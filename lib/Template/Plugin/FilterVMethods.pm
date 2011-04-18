package Template::Plugin::FilterVMethods;

use utf8;
use Moose;
use MooseX::NonMoose;
use MooseX::ClassAttribute;
use MooseX::FollowPBP;
use MooseX::Types::Moose qw/ArrayRef HashRef Str Bool/;
use List::AllUtils qw/any uniq/;
use namespace::autoclean;
use constant 'FilterVMethods' => __PACKAGE__;

extends 'Template::Plugin';

our $VERSION = '0.04';

=encoding utf-8

=head1 NAME

Template::Plugin::FilterVMethods - Add a .filter vmethod, or add individual filters as individual vmethods. 

=head1 SYNOPSIS

	[% USE FILTERVMETHODS %]

	[% voice = '  loud  ' %]
	[% IF voice.filter('trim').filter('upper') == 'LOUD' %]
	STOP YELLING AT ME
	[% END %]

or

	[% USE FilterVMethods('trim', 'upper') %]
	[%# Pass the argument ":all" to import all available filters. %]

	[% voice = '  loud  ' %]
	[% IF voice.trim.upper == 'LOUD' %]
	I'M NOT YELLING
	[% END %]

=head1 DESCRIPTION

This plugin provides a C<.filter> virtual method and, optionally, virtual methods for any filter, to make for an alternative,
more flexible filtering syntax. In comparison with the synopsis examples, mixing filters with other syntax often just doesn't
work:

	[% IF voice FILTER trim FILTER upper == 'LOUD' %]
	[%# Couldn't render template "my_template.txt: file error - parse error - my_template.txt line 1: unexpected token (FILTER) %]

	[% IF (voice FILTER trim FILTER upper) == 'LOUD' %]
	[%# Couldn't render template "my_template.txt: file error - parse error - my_template.txt line 1: unexpected token (FILTER) %]

The syntactically sound way to do this is to filter the variable (or a copy thereof) beforehand. Now a template writer can simply
use a filter as a vmethod instead.

=head1 CONFIGURATION

In case there is a risk of vmethod-name collisions, L<Template::Plugin::FilterVMethods> accepts one configuration setting, C<FMV_PREFIX>.
This can be set to a string containing characters within C<[a-z_]> and will be prepended to all vmethods except C<.filter> itself:

	my $tt = Template->new({ FMV_PREFIX => 'f_' });

=cut

has 'context', (
	isa        => 'Template::Context',
	is         => 'ro',
	required   => 1,
);
has 'config', (
	isa        => HashRef,
	is         => 'ro',
	lazy_build => 1,
);
has 'requested_filters', (
	isa        => ArrayRef[Str],
	is         => 'ro',
	required   => 1,
);
has 'filter_prefix', (
	isa        => Str,
	is         => 'ro',
	lazy_build => 1,
);

# vmethods defined by something other than Template::Plugin::FilterVMethods
has 'other_vmethods', (
	isa        => HashRef,
	is         => 'rw',
	reader     => 'get_other_vmethods',
	writer     => 'set_other_vmethods',
);
# vmethods defined by Template::Plugin::FilterVMethods. A class attribute
# so as to share the list between multiple [% USE FilterVMethods %] calls.
class_has 'fvm_vmethods', (
	isa        => HashRef[Bool],
	is         => 'rw',
	reader     => 'get_fvm_vmethods',
	writer     => 'set_fvm_vmethods',
	default    => sub { {} },
);

# Refresh list of other vmethods before every access:
before 'get_other_vmethods', sub {
	my $self = shift;
	my %other_vmethods;
	{
		no warnings 'once';
		%other_vmethods = (
			%$Template::Stash::ROOT_OPS,
			%$Template::Stash::SCALAR_OPS,
		);
	}
	my $fmv_vmethods = $self->get_fvm_vmethods;
	foreach my $vmethod_name (keys %other_vmethods) {
		delete $other_vmethods{$vmethod_name} if $fmv_vmethods->{$vmethod_name};
	}
	$self->set_other_vmethods(\%other_vmethods);
};

sub BUILDARGS {
	my ($class, $context, @requested_filters) = @_;
	#@requested_filters = ('filter') if !@requested_filters;
	@requested_filters = uniq @requested_filters;
	return $class->SUPER::BUILDARGS(
		context           => $context,
		requested_filters => \@requested_filters,
	);
}
sub BUILD {
	my $self = shift;
	my $context = $self->get_context;
	my $config = $self->get_config;
	$config->{'FVM_PREFIX'} = '' if !exists $config->{'FVM_PREFIX'};
	return FilterVMethods->error("FVM_PREFIX includes characters outside [a-z_].")
		if $config->{'FVM_PREFIX'} =~ /[^a-z_]/;

	my $requested_filters = $self->get_requested_filters;
	# if requested to get all available filters:
	if ( any {$_ eq ':all'} @$requested_filters ) {
		# Get core filters:
		my @available_filters;
		{
			require Template::Filters;
			no warnings 'once';
			@available_filters = keys %$Template::Filters::FILTERS;
		}
		
		# Get plugin filters:
		foreach my $plugin ( @{ $context->{'LOAD_FILTERS'} } ) {
			foreach my $filter_name ( keys %{ $plugin->{'FILTERS'} } ) {
				push @available_filters, $filter_name;
			}
		}
		$requested_filters = \@available_filters;
	}

	# Define a vmethod for each filter:
	my $prefix = $self->get_filter_prefix;
	my $fvm_vmethods = FilterVMethods->get_fvm_vmethods;
	my $other_vmethods = $self->get_other_vmethods;
	foreach my $filter_name (@$requested_filters) {
		$filter_name = $prefix . $filter_name;
		next if any { $filter_name eq $_ } 'replace', 'remove';
		if ( $other_vmethods->{$filter_name} ) {
			return FilterVMethods->error("Virtual-method name collision on '$filter_name'");
		} elsif ( !$fvm_vmethods->{$filter_name} ) {
			my $sub = sub { $self->get_filter_sub($filter_name, @_) };
			$context->define_vmethod('scalar', $filter_name, $sub);
			$fvm_vmethods->{$filter_name} = 1;
		}
	}
	
	# Define the 'filter' vmethod:
	if ( !$fvm_vmethods->{'filter'} ) {
		$context->define_vmethod('scalar', 'filter', sub { $self->use_filter(@_) } );
		$fvm_vmethods->{'filter'} = 1;
	}
}

# For using a filter as in "some_var.filter('filter_name')":
sub use_filter {
	my ($self, $value, $filter_name, @args) = @_;
	return FilterVMethods->error('At least one argument (a filter name) is required.')
		if !defined $filter_name;
	my $context = $self->get_context;
	my $filter = $context->filter($filter_name, \@args);
	return $filter->($value);
}

# For using a filter as in "some_var.filter_name"
sub get_filter_sub {
	my ($self, $filter_name, $value, @args) = @_;
	my $prefix = $self->get_filter_prefix;
	$filter_name =~ s/^$prefix//;
	my $context = $self->get_context;
	my $filter = $context->filter($filter_name, \@args);
	return $filter->($value);
}
sub _build_config {
	my $self = shift;
	my $context = $self->get_context;
	return $context->{'CONFIG'};
}
sub _build_filter_prefix {
	my $self = shift;
	my $config = $self->get_config;
	return defined $config->{'FVM_PREFIX'} ? $config->{'FVM_PREFIX'} : '';
}

=head1 AUTHOR

Richard Simões, C<< <rsimoes at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Yuval Kogman for writing a handy example of a Moose-ified Template Toolkit plugin, L<Template::Plugin::JSON>.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Richard Simões.

This document may be freely modified and distributed under the same terms as Perl itself. See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Template::Filters>, L<Template::Manual::Filters>

=cut

__PACKAGE__->meta->make_immutable;
1;
