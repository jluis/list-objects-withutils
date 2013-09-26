package List::Objects::WithUtils::Array::Immutable;
use strictures 1;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Array
    List::Objects::WithUtils::Role::WithJunctions
  /
);
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Array::Immutable
  /,
);

use Exporter 'import';
our @EXPORT = 'immarray';
sub immarray { __PACKAGE__->new(@_) }

1;

=pod

=head1 NAME

List::Objects::WithUtils::Array::Immutable - Immutable array objects

=head1 SYNOPSIS

  use List::Objects::WithUtils 'immarray';

  my $array = immarray(qw/ a b c /);

  my ($head, $rest) = $array->head;

=head1 DESCRIPTION

These are immutable array objects; attempting to call list-mutating methods
will throw an exception.

On Perls which support it properly, the array is also marked read-only;
manually modifying the backing ARRAY reference will also throw an exception.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Array>

L<List::Objects::WithUtils::Role::Array::WithJunctions>

L<List::Objects::WithUtils::Role::Array::Immutable>

(See L<List::Objects::WithUtils::Array> for the mutable implementation.)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
