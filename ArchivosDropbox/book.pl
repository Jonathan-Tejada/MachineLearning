    use strict;
    use warnings;
    use Encode;
    use utf8;
    use Config;
    binmode STDOUT, ":utf8";
    binmode STDERR, ":utf8";
    use Data::Dump qw(dump);
    use PDL;
    use d2l;
    use AI::MXNet qw(mx);
    use AI::MXNet qw(nd);
    use AI::MXNet::AutoGrad qw(autograd);
    use AI::MXNet::Base;#zip, enumerate, product, bisect_left, pdl_shuffle, assert, check_call, build_param_doc

    #Sección de codigos de las funciones traducidas a Perl del libro d2l. Las funciones de la librería d2l deben ser definidas en d2l.pm.
    #This file will be constantly updated.

    my $d2l = d2l->new();


    #0 - Assigning values to piddles. 
    #my $pdla = sequence(10);
    #my $pdlb = sequence(10) + 5;
    #my $pdlc = sequence(10) % 2;
    #print $pdla."\n".$pdlb."\n".$pdlc."\n";
    
    sub zippdl (&@){#Each pdl is a one dimensional row vector
      my $self = shift;
      my $min;
      $min = $min && $_->getdim(0) > $min ? $min : $_->getdim(0) for @_;#Obtaining the shortest pdl's dimension
      for my $row (0 .. $min-1){ $self->(map $_->at($row), @_) }
    }

=pod
    #1 - #Iterates and returns tuple by tuple of a one dimensional row vector
    zippdl{
      my ($x, $y, $z) = @_;
      #print "x=".$x." y=".$y." z=".$z."\n";
      #print "";
    }($pdla, $pdlb, $pdlc);
=cut

    #2 - Which is different from concatenating everything together into the same piddle
    #print $d2l->concat_transpose($pdla, $pdlb, $pdlc),"\n";
    
    #3 - Fetches pi number defined in d2l
    #print "pi=".$d2l->{pi},"\n";


    #4 - Examples of PDL PreProcessor functions for creating brand new pdl methods from scratch.
    #https://master.dl.sourceforge.net/project/pdl/PDL/2.4.10/PDL-Book-20120205.pdf
    #Refer to Chapter 11: The PDL PreProcessor
    
    ##my $pdla = sequence 10;
    #print $pdla->inc,"\n";
    
    #print $pdla->inc->dummy(1,10)->tcumul,"\n";
    
    #print "pdla is $pdla and its sumover is ",$pdla->my_sumover,"\n";
    
    #my $pdld = sequence(3, 5);
    
    #print "pdld is $pdld and its sumover is ",$pdld->my_sumover,"\n";
    
    #$d2l->use_svg_display();#Generates an .svg plot file in the subdirectory of this .pl script.

    #5 - Defined in file: ./chapter_preliminaries/calculus.md
    sub f{
      my ($x) = @_;
      return 3 * $x** 2 - 4 * $x;
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    sub numerical_lim{
      my ($x, $h) = @_;
      return (f($x + $h) - f($x)) / $h;
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    my $h = 0.1;
    #print numerical_lim(1, $h)."\n";

    # Defined in file: ./chapter_preliminaries/calculus.md
    for my $i (1 .. 5){
       print "h=".sprintf ("%.5f", $h) .", numerical limit=".sprintf ("%.5f", numerical_lim(1, $h))."\n";
       $h *= 0.1;
    }

    # Defined in file: ./chapter_preliminaries/calculus.md
    my $pdlfigsize = pdl [640, 480];
    my $pdlx = sequence(30) / 10;
    #print $pdlx."\n";
    #print f($pdlx)."\n";
    my $pdly = pdl [f($pdlx), 2 * $pdlx - 3];
    #print $pdly."\n";
    my @legend_arr = ('f(x)', 'Tangent line (x=1)');#
    
    $d2l->plot($pdlx, $pdly, 'x', 'f(x)', \@legend_arr, undef, undef, 'linear', 'linear', undef, $pdlfigsize, undef);
    print "(Press <RETURN> to continue)"; $a=<>;


    #6 - Defined in file: ./chapter_preliminaries/probability.md
    
    my $pdlprobabilities = ones(6) / 6;
    #print "probabilities=", $pdlprobabilities."\n";
    my $num_rolls = 1000;
    
    my $ndrolls = nd->random->multinomial(mx->nd->array($pdlprobabilities), shape=>[$num_rolls]);
    my $pdlrolls = $ndrolls->aspdl;
    #print "rolls=", $ndrolls->aspdl, "\n";
    
    #my $counts = mx->nd->zeros([6, $num_rolls]);
    my $pdlcounts = zeros($num_rolls, 6);
    #print "counts=", $pdlcounts;
    
    my $pdltotals = zeros(6)->reshape(1, 6);#$totals = mx->nd->zeros([6])->reshape([6, 1]);
    #print "totals=", $pdltotals."\n";

    #nd iteration
    enumerate(sub {                                                               
        my ($i, $roll) = @_;
        #print "roll=", $roll, "\n";
        $pdltotals->slice(0, $roll->asscalar) += 1;
        #print "i=", $i, " totals=", $pdltotals."\n";
        $pdlcounts->slice("$i, :") += $pdltotals;
    }, \@{ $ndrolls });

=pod
    #pdl iteration
    enumerate(sub {                                                               
        my ($i, $roll) = @_;
        #print "roll=", $roll, "\n";
        $pdltotals->slice(0, $roll) += 1;#$ndroll->asscalar
        #print "i=", $i, " totals=", $pdltotals."\n";
        $pdlcounts->slice("$i, :") += $pdltotals;
    }, \@{ unpdl $pdlrolls });
=cut

    #print "totals=", $pdltotals."\n";
    #print $pdltotals / $num_rolls, "\n";
    #print "counts=", $pdlcounts;
    
    my $pdlnorm = sequence($num_rolls)->reshape($num_rolls, 1) + 1;
    #print $pdlnorm, "\n";

    my $pdlestimates = $pdlcounts / $pdlnorm;

    #print $pdlestimates, "\n";
    #print $pdlestimates->slice("1,:");
    #print $pdlestimates->slice("9,:");
    @legend_arr = ();
    push @legend_arr, "P(die=$_)" for (1 .. 6);

    $d2l->plot($pdlestimates, undef, 'Groups of experiments', 'Estimated probability', \@legend_arr, undef, undef, 'linear', 'linear', undef, $pdlfigsize, undef);
    $d2l->{axes}->replot(legend=>"Average probability", with=>"linespoints", linecolor=>'black', linetype=>2, ones($num_rolls) * 0.167);#https://stackoverflow.com/questions/19412382/gnuplot-line-types
    print "(Press <RETURN> to continue)"; $a=<>;

    #Dear student, place the book translation and test below ...

    
=pod
    #To be revised under PDL/Komodo/Command line interpreter
    #7 - Test code for d2l function 'synthetic_data'
	$true_w=mx->nd->array([2,-3.4]);
	$true_b=4.2;
	@arr_res=&synthetic_data($true_w,$true_b,1000);
	print $arr_res[0]->aspdl;
	print $arr_res[1]->aspdl;

    
    #8 - Test code for d2l function 'linreg'
	$X=mx->nd->random_normal(0,1,shape=>[100,2]);
	$w=mx->nd->array([2,-3.4]);
	$b=4.2;
	$linreg=&linreg($X,$w,$b);
	print $linreg->aspdl;
    
    #9 - Test code for 'squared_loss'
	$X=mx->nd->random_normal(0,1,shape=>[100,2]);
	$w=mx->nd->array([2,-3.4]);
	$b=4.2;
	$y=&linreg($X,$w,$b);
	print ($y->aspdl);

    
    #10 - Test code for 'sgd'
=cut






