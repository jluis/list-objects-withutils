use Test::More;
use strict; use warnings;

use List::Objects::WithUtils 'array';

my $arr = array('a' .. 'f');
my %as_hash = (map {; $_ => 1 } $arr->all );

my $rolled = $arr->roll(3);
ok $rolled->count == 3, 'rolled three items';
for my $item ($rolled->all) {
  ok exists $as_hash{$item}, "rolled item '$item' ok";
}

done_testing
