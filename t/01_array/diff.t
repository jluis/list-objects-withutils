use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $first  = array(qw/a b c d e /);
my $second =      [qw/a b c x y /];

my $diff = $first->diff($second);
is_deeply
  [ $diff->sort->all ],
  [ qw/d e x y / ],
  'two-array diff ok'
  or diag explain $diff;

my $third = array(qw/a b c x z /);
$diff = $first->diff($second, $third);
is_deeply
  [ $diff->sort->all ],
  [ qw/d e x y z/ ],
  'three-array diff ok'
  or diag explain $diff;

done_testing