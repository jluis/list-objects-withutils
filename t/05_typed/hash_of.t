
BEGIN {
  unless (
    eval {; require List::Objects::Types; 1 } && !$@
    && eval {; require Types::Standard; 1 }   && !$@
  ) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require List::Objects::Types and Types::Standard'
    );
  }
}

use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::Types -all;
use Types::Standard -all;


# hash_of
{
  use List::Objects::WithUtils 'hash_of';
  my $h = hash_of Int() => (foo => 1, bar => 2);
  ok $h->type == Int, 'type returned Int ok';
  ok !hash->type, 'plain HashObj has no type ok';

  eval {; my $bad = hash_of( Int() => qw/foo 1 bar baz/) };
  ok $@ =~ /constraint/, 'array_of invalid type died ok' or diag explain $@;

  eval {; $h->set(baz => 3.14159) };
  ok $@ =~ /type/, 'invalid type set died ok';
  ok $h->set(baz => 3), 'valid type set ok';
  ok $h->keys->count == 3, 'count ok after set';
}

# tied hash
{
  use List::Objects::WithUtils 'hash_of';
  my $h = hash_of Int() => (foo => 1, bar => 2);

  eval {; $h->{foo} = 'bar' };
  ok $@ =~ /type/, 'invalid type set died ok';
}

done_testing;
