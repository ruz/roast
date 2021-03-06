use v6;
use Test;

# L<S12/Classes/You can predeclare a stub class>

plan 7;

eval_lives_ok q[ class StubA { ... }; class StubA { method foo { } }; ],
              'Can stub a class, and later on declare it';
eval_lives_ok q[ role StubB { ... }; role StubB { method foo { } }; ],
              'Can stub a role, and later on declare it';
eval_lives_ok q[ module StubC { ... }; module StubC { sub foo { } }; ],
              'Can stub a module, and later on declare it';

#?niecza skip 'broken in nom-derived stub model'
eval_lives_ok q[ package StubD { ... }; class StubD { method foo { } }; ],
              'Can stub a package, and later on implement it as a method';

# not quite class stubs, but I don't know where else to put the tests...

lives_ok { sub {...} }, 'not execued stub code is fine';
dies_ok { (sub {...}).() ~ '' }, 'execued stub code goes BOOM when used';
dies_ok { use fatal; (sub { ... }).() }, 'exeucted stub code goes BOOM under fatal';

# vim: ft=perl6
