package List::Objects::WithUtils::Role::Hash;

use strictures 1;

use Module::Runtime ();
use Scalar::Util    ();
use List::Util      ();

=pod

=for Pod::Coverage HASH_TYPE blessed_or_pkg

=cut

sub HASH_TYPE () { 'List::Objects::WithUtils::Hash' }
sub blessed_or_pkg { 
  Scalar::Util::blessed($_[0]) ?
    $_[0] : Module::Runtime::use_module(HASH_TYPE)
}

use Role::Tiny;

sub array_type       { 'List::Objects::WithUtils::Array' }
sub inflated_type    { 'List::Objects::WithUtils::Hash::Inflated' }
sub inflated_rw_type { 'List::Objects::WithUtils::Hash::Inflated::RW' }

=pod

=for Pod::Coverage TO_JSON damn type

=cut

sub is_mutable   { 1 }
sub is_immutable { ! $_[0]->is_mutable }

sub type { }

our %Required;
sub new {
  my $arraytype = $_[0]->array_type;
  unless (exists $Required{$arraytype}) {
    Module::Runtime::require_module($arraytype);
    $Required{$arraytype} = 1
  }
  bless +{ @_[1 .. $#_] }, Scalar::Util::blessed($_[0]) || $_[0]
}

sub export  { %{ $_[0] } }
sub unbless { +{ %{ $_[0] } } }

{ no warnings 'once'; *TO_JSON = *unbless; *damn = *unbless; }

sub clear { %{ $_[0] } = (); $_[0] }

=pod

=for Pod::Coverage untyped

=cut

sub copy { blessed_or_pkg($_[0])->new(%{ $_[0] }) }
{ no warnings 'once'; *untyped = *copy; }

sub inflate {
  my ($self, %params) = @_;
  my $type = $params{rw} ? 'inflated_rw_type' : 'inflated_type';
  my $pkg = blessed_or_pkg($self);
  Module::Runtime::require_module( $pkg->$type );
  $pkg->$type->new( %$self )
}

sub defined { CORE::defined $_[0]->{ $_[1] } }
sub exists  { CORE::exists  $_[0]->{ $_[1] } }

sub is_empty { ! keys %{ $_[0] } }

sub get {
  if (@_ > 2) {
    return blessed_or_pkg($_[0])->array_type->new(
      @{ $_[0] }{ @_[1 .. $#_] }
    )
  }
  $_[0]->{ $_[1] }
}

sub get_or_else {
  exists $_[0]->{ $_[1] } ? $_[0]->{ $_[1] }
    : (Scalar::Util::reftype $_[2] || '') eq 'CODE' ? $_[2]->(@_[0,1])
    : $_[2]
}

sub get_path {
  my $ref = $_[0];
  for my $part (@_[1 .. $#_]) {
    $ref = ref $part eq 'ARRAY' ? $ref->[ $part->[0] ] : $ref->{$part};
    return undef unless defined $ref;
  }
  $ref
}

=pod

=for Pod::Coverage slice

=cut

{ no warnings 'once'; *slice = *sliced; }
sub sliced {
  blessed_or_pkg($_[0])->new(
    map {; exists $_[0]->{$_} ? ( $_ => $_[0]->{$_} ) : () } @_[1 .. $#_]
  )
}

sub set {
  my $self = shift;

  my (@keysidx, @valsidx);
  for (0 .. $#_) {
    $_ % 2 ? push @valsidx, $_ : push @keysidx, $_
  }

  @{$self}{ @_[@keysidx] } = @_[@valsidx];

  $self
}

sub maybe_set {
  my $self = shift;
  for (grep {; not $_ % 2 } 0 .. $#_) {
    $self->{ $_[$_] } = $_[$_ + 1] unless exists $self->{ $_[$_] }
  }
  $self
}

sub delete {
  blessed_or_pkg($_[0])->array_type->new(
    CORE::delete @{ $_[0] }{ @_[1 .. $#_] }
  )
}

sub keys {
  blessed_or_pkg($_[0])->array_type->new(
    CORE::keys %{ $_[0] }
  )
}

sub values {
  blessed_or_pkg($_[0])->array_type->new(
    CORE::values %{ $_[0] }
  )
}

sub intersection {
  my %seen; my %inner;
  blessed_or_pkg($_[0])->array_type->new(
    grep {; not $seen{$_}++ }
      grep {; ++$inner{$_} > $#_ } map {; CORE::keys %$_ } @_
  )
}

sub diff {
  my %seen; my %inner;
  my @vals = map {; CORE::keys %$_ } @_;
  $seen{$_}++ for @vals;
  blessed_or_pkg($_[0])->array_type->new(
    grep {; $seen{$_} != @_ } 
      grep {; not $inner{$_}++ } @vals
  )
}

sub iter {
  my @list = %{ $_[0] };
  sub { splice @list, 0, 2 }
}

sub kv {
  blessed_or_pkg($_[0])->array_type->new(
    map {; [ $_, $_[0]->{ $_ } ] } CORE::keys %{ $_[0] }
  )
}

sub kv_sort {
  if (defined $_[1]) {
    return blessed_or_pkg($_[0])->array_type->new(
      map {; [ $_, $_[0]->{ $_ } ] }
        sort {; $_[1]->($a, $b) } CORE::keys %{ $_[0] }
    )
  }
  blessed_or_pkg($_[0])->array_type->new(
    map {; [ $_, $_[0]->{ $_ } ] } sort( CORE::keys %{ $_[0] } )
  )
}

sub kv_map {
  my ($self, $sub) = @_;
  blessed_or_pkg($self)->array_type->new(
    List::Util::pairmap {; $sub->($a, $b) } %$self
  )
}

=pod

=for Pod::Coverage invert

=cut

sub inverted {
  my ($self) = @_;
  my $pkg = blessed_or_pkg($self);
  my %new;
  List::Util::pairmap {;
    exists $new{$b} ?
      $new{$b}->push($a) : ( $new{$b} = $pkg->array_type->new($a) )
  } %$self;
  $pkg->new(%new)
}
{ no warnings 'once'; *invert = *inverted; }


print
  qq[<Su-Shee> huf: I learned that from toyota via agile blahblah,],
  qq[ it's asking the five "why" questions.\n],
  qq[<mauke> WHY WHY WHY WHY GOD WHY\n]
unless caller;
1;


=pod

=head1 NAME

List::Objects::WithUtils::Role::Hash - Hash manipulation methods

=head1 SYNOPSIS

  ## Via List::Objects::WithUtils::Hash ->
  use List::Objects::WithUtils 'hash';

  my $hash = hash(foo => 'bar');

  $hash->set(
    foo => 'baz',
    pie => 'tasty',
  );

  my @matches = $hash->keys->grep(sub {
    $_[0] =~ /foo/
  })->all;

  my $pie = $hash->get('pie')
    if $hash->exists('pie');

  for my $pair ( $hash->kv->all ) {
    my ($key, $val) = @$pair;
    ...
  }

  my $obj = $hash->inflate;
  my $foo = $obj->foo;

  ## As a Role ->
  use Role::Tiny::With;
  with 'List::Objects::WithUtils::Role::Hash';

=head1 DESCRIPTION

A L<Role::Tiny> role defining methods for creating and manipulating HASH-type
objects.

In addition to the methods documented below, these objects provide a
C<TO_JSON> method exporting a plain HASH-type reference for convenience when
feeding L<JSON::Tiny> or similar.

=head2 Basic hash methods

=head3 new

Constructs a new HASH-type object.

=head3 copy

Creates a shallow clone of the current object.

=head3 defined

  if ( $hash->defined($key) ) { ... }

Returns boolean true if the key has a defined value.

=head3 exists

  if ( $hash->exists($key) ) { ... }

Returns boolean true if the key exists.

=head3 export

  my %hash = $hash->export;

Returns a raw key/value list.

=head3 array_type

The class name of array-type objects that will be used to contain the results
of methods returning a list.

Defaults to L<List::Objects::WithUtils::Array>.

Subclasses can override C<array_type> to produce different types of array
objects.

=head3 inflate

  my $obj = hash(foo => 'bar', baz => 'quux')->inflate;
  my $baz = $obj->baz; 

Inflates a simple object providing accessors for a hash.

By default, accessors are read-only; specifying C<rw => 1> allows setting new
values:

  my $obj = hash(foo => 'bar', baz => 'quux')->inflate(rw => 1);
  $obj->foo('frobulate');

Returns an L</inflated_type> (or L</inflated_rw_type>) object.

The default objects provide a C<DEFLATE> method returning a
plain hash; this makes it easy to turn inflated objects back into a C<hash()>
for modification:

  my $first = hash( foo => 'bar', baz => 'quux' )->inflate;
  my $second = hash( $first->DEFLATE, frobulate => 1 )->inflate;

=head3 inflated_type

The class name that objects are blessed into when calling L</inflate>.

Defaults to L<List::Objects::WithUtils::Hash::Inflated>.

=head3 inflated_rw_type

The class name that objects are blessed into when calling L</inflate> with
C<rw => 1>.

Defaults to L<List::Objects::WithUtils::Hash::Inflated::RW>, a subclass of
L<List::Objects::WithUtils::Hash::Inflated>.

=head3 is_empty

Returns boolean true if the hash has no keys.

=head3 is_mutable

Returns boolean true if the hash is mutable; immutable subclasses can override
to provide a negative value.

=head3 is_immutable

The opposite of L</is_mutable>.

=head3 unbless

Returns a plain C</HASH> reference (shallow clone).

=head2 Methods that manipulate the hash

=head3 clear

Clears the current hash entirely.

Returns the hash object.

=head3 delete

  $hash->delete( @keys );

Deletes the given keys from the hash.

Returns an L</array_type> object containing the deleted values.

=head3 set

  $hash->set(
    key1 => $val,
    key2 => $other,
  )

Sets keys in the hash.

Returns the current hash object.

=head3 maybe_set

  my $hash = hash(foo => 1, bar => 2, baz => 3);
  $hash->maybe_set(foo => 2, bar => 3, quux => 4);
  # $hash = +{ foo => 1, bar => 2, baz => 3, quux => 4 }

Like L</set>, but only sets values that do not already exist in the hash.

Returns the hash object.

=head2 Methods that retrieve items

=head3 get

  my $val  = $hash->get($key);
  my @vals = $hash->get(@keys)->all;

Retrieves a key or list of keys from the hash.

If we're taking a slice (multiple keys were specified), values are returned
as an L</array_type> object. (See L</sliced> if you'd rather generate a new
hash.)

=head3 get_path

  my $hash = hash(
    foo => +{
      bar => +{
        baz => 1
      }
    },
    quux => [
      +{ weeble => 'snork' }
    ],
  );

  my $item = $hash->get_path(qw/foo bar baz/);        # 1

Attempt to retrieve a scalar item from a 'deep' hash (without risking
autovivification).

If an element of the given path is a (plain) array reference, as in this
example:

  my $item = $hash->get_path('quux', [1], 'weeble');  # "snork"

... then it is taken as the index of an array or array-type object in the
path.

Returns undef if any of the path elements are nonexistant.
  
An exception is thrown if an invalid access is attempted, such as trying to
use a hash-type object as if it were an array.

(Available from v2.15.1)

=head3 get_or_else

  # Expect to find an array() obj at $key in $hash,
  # or create an empty one if $key doesn't exist:
  my @all = $hash->get_or_else($key => array)->all;

  # Or pass a coderef
  # First arg is the object being operated on
  # Second arg is the requested key
  my $item = $hash->get_or_else($key => sub { shift->get($defaultkey) });

Retrieves a key from the hash; optionally takes a second argument that is used
as a default value if the given key does not exist in the hash.

If the second argument is a coderef, it is invoked on the object (with the
requested key as an argument) and its return value is taken as the default
value.

=head3 keys

  my @keys = $hash->keys->all;

Returns the list of keys in the hash as an L</array_type> object.

=head3 values

  my @vals = $hash->values->all;

Returns the list of values in the hash as an L</array_type> object.

=head3 inverted

  my $hash = hash(
    a => 1,
    b => 2,
    c => 2,
    d => 3
  );
  my $newhash = $hash->inverted;
  # $newhash = +{
  #   1 => array('a'),
  #   2 => array('b', 'c'),
  #   3 => array('d'),
  # }

Inverts the hash, creating L</array_type> objects containing one or more keys
for each unique value.

This is a bit like reversing the hash, but lossless.

(Available from v2.14.1)

=head3 iter

  my $iter = $hash->iter;
  while (my ($key, $val) = $iter->()) {
    # ...
  }

Returns an iterator that, when called, returns ($key, $value) pairs.

The iterator operates on a shallow clone of the current hash, making it
(relatively) safe to operate on the original hash while using the iterator.

(Available from v2.9.1)

=head3 kv

  for my $pair ($hash->kv->all) {
    my ($key, $val) = @$pair;
  }

Returns an L</array_type> object containing the key/value pairs in the hash,
each of which is a two-element (unblessed) ARRAY.

=head3 kv_map

  # Add 1 to each value, get back an array-type object:
  my $kvs = hash(a => 2, b => 2, c => 3)
    ->kv_map(sub { ($_[0], $_[1] + 1) });

Like C<map>, but operates on pairs. See L<List::Util/"pairmap">. 

Returns an L</array_type> object containing the results of the map.

(Available from v2.8.1)

=head3 kv_sort

  my $kvs = hash(a => 1, b => 2, c => 3)->kv_sort;
  # $kvs = array(
  #          [ a => 1 ], 
  #          [ b => 2 ], 
  #          [ c => 3 ]
  #        )

  my $reversed = hash(a => 1, b => 2, c => 3)
    ->kv_sort(sub { $_[1] cmp $_[0] });
  # Reverse result as above

Like L</kv>, but sorted by key. A sort routine can be provided; C<$_[0]> and
C<$_[1]> are equivalent to the usual sort variables C<$a> and C<$b>.

=head3 sliced

  my $newhash = $hash->sliced(@keys);

Returns a new hash object built from the specified set of keys.

(See L</get> if you only need the values.)

=head2 Methods that compare hashes

=head3 intersection

  my $first  = hash(a => 1, b => 2, c => 3);
  my $second = hash(b => 2, c => 3, d => 4);
  my $intersection = $first->intersection($second);
  my @common = $intersection->sort->all;

Returns the list of keys common between all given hash-type objects (including
the invocant) as an L</array_type> object.

=head3 diff

The opposite of L</intersection>; returns the list of keys that are not common
to all given hash-type objects (including the invocant) as an L</array_type>
object.

=head1 SEE ALSO

L<List::Objects::WithUtils>

L<List::Objects::WithUtils::Hash>

L<List::Objects::WithUtils::Hash::Immutable>

L<List::Objects::WithUtils::Hash::Typed>

L<Data::Perl>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Portions of this code are derived from L<Data::Perl> by Matthew Phillips
(CPAN: MATTP), haarg et al

Licensed under the same terms as Perl.

=cut
