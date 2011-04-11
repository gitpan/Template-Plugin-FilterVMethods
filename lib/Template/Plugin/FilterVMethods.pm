package Template::Plugin::FilterVMethods;

use Moose;
use MooseX::ClassAttribute;
use MooseX::FollowPBP;
use MooseX::NonMoose;
use MooseX::Types::Moose qw/ArrayRef HashRef Str/;
use List::AllUtils 'any';
use namespace::autoclean;

extends 'Template::Plugin';
our $VERSION = '0.01';

=head1 NAME

Template::Plugin::FilterVMethods - Add a .filter vmethod, or add individual filters as individual vmethods. 

=head1 SYNOPSIS

	[% USE FilterVMethods %]

	[% voice = '  loud  ' %]
	[% IF voice.filter('trim').filter('upper') == 'LOUD' %]
	STOP YELLING AT ME!
	[% END %]

or

	[% USE FilterVMethods('trim', 'upper') %]

	[% voice = '  loud  ' %]
	[% IF voice.trim.upper == 'LOUD' %]
	I'M NOT YELLING!
	[% END %]


=head1 DESCRIPTION

This plugin provides a C<.filter> virtual method and, optionally, virtual methods for any filter, to make for an alternative,
more flexible filtering syntax. In comparison with the synopsis examples, mixing filters with other syntax often just doesn't
work:

	[% IF voice FILTER trim FILTER upper == 'LOUD' %]
	# Couldn't render template "my_template.txt: file error - parse error - my_template.txt line 1: unexpected token (FILTER)

	[% IF (voice FILTER trim FILTER upper) == 'LOUD' %]
	# Couldn't render template "my_template.txt: file error - parse error - my_template.txt line 1: unexpected token (FILTER)

The syntactically sound way to do this is filter the variable (or a copy thereof) beforehand. Now a template writer can simply
use a filter as a vmethod.

=head1 CONFIGURATION

To help avoid vmethod name collisions, Template::Plugin::FilterVMethods accepts one configuration setting, C<FMV_PREFIX>. This
can be set to a string containing characters within C<[a-z_]> and will be prepended to all vmethods except C<.filter> itself.

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
has 'filter_names', (
	isa        => ArrayRef[Str],
	is         => 'ro',
	required   => 1,
);
class_has 'installed_vmethods', (
	isa        => ArrayRef[Str],
	is         => 'rw',
	reader     => 'get_installed_vmethods',
	default    => sub { [] },
);

sub BUILDARGS {
	my ($class, $context, @filter_names) = @_;
	@filter_names = ('filter') if !@filter_names;
	return $class->SUPER::BUILDARGS(
		context      => $context,
		filter_names => \@filter_names,
	);
}
sub BUILD {
	my $self = shift;
	my $context = $self->get_context;
	my $filter_names = $self->get_filter_names;

	if ($filter_names->[0] eq ':all') { # Option to get all available filters.
		# Get pre-bundled filters:
		my @bundled_filters;
		{
			no warnings 'once';
			@bundled_filters = keys %$Template::Filters::FILTERS;
		}
		$filter_names = ['filter', @bundled_filters];
		
		# Get plugin filters:
		foreach my $plugin ( @{ $context->{'LOAD_FILTERS'} } ) {
			foreach my $filter_name ( keys %{ $plugin->{'FILTERS'} } ) {
				push @$filter_names, $filter_name;
			}
		}
	}
	
	# Create a vmethod for each filter:
	my $config = $self->get_config;
	my @preexisting_vmethods;
	{
		no warnings 'once';
		@preexisting_vmethods = (
			keys(%$Template::Stash::ROOT_OPS),
			keys(%$Template::Stash::SCALAR_OPS),
		);
	}
	my $prefix = defined $config->{'FVM_PREFIX'} ? $config->{'FVM_PREFIX'} : '';
	$self->error("FVM_PREFIX includes characters outside [a-z_].") if $prefix =~ /[^a-z_]/;
	my $installed_vmethods = Template::Plugin::FilterVMethods->get_installed_vmethods;
	foreach my $filter_name (@$filter_names) {
		my $sub;
		if ( any { $filter_name eq $_ }  @$installed_vmethods ) {
			next;
		} elsif ($filter_name eq 'filter') {
			$sub = sub { $self->filter_vm(@_) };
		} elsif($filter_name eq 'replace') {            # Skip to avoid overwriting the core ".replace" vmethod
			next;
		} elsif( any { $filter_name eq $_ }  @preexisting_vmethods ) {
			$self->error("Virtual method name collision on $filter_name");
		} else {
			$sub = sub { $self->particular_filter_vm("$prefix$filter_name", @_) };
		} 
		$context->define_vmethod('scalar', $filter_name, $sub);
		push @$installed_vmethods, $filter_name;
	}
}

# For using a filter as in "some_var.filter('html')":
sub filter_vm {
	my ($self, $value, $filter_name, @args) = @_;
	return $self->error('No filter name provided') if !defined $filter_name;
	my $context = $self->get_context;
	my $filter = $context->filter($filter_name, \@args);
	return $filter->($value);
}

# For using a filter as in "some_var.html"
sub particular_filter_vm {
	my ($self, $filter_name, $value, @args) = @_;
	my $context = $self->get_context;
	my $filter = $context->filter($filter_name, \@args);
	return $filter->($value);
}

sub _build_config {
	my $self = shift;
	my $context = $self->get_context;
	return $context->{'CONFIG'};
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
