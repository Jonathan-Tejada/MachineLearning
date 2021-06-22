    use d2l;
    use strict;
    use warnings;
    use Encode;
    use utf8;
    use Config;
    binmode STDOUT, ":utf8";
    binmode STDERR, ":utf8";
    use Data::Dump qw(dump);
    use List::Util qw(shuffle);
    use PDL;#https://manpath.be/f32/1/PDL::Scilab
    use AI::MXNet qw(mx);
    use AI::MXNet qw(nd);
    use AI::MXNet::AutoGrad qw(autograd);
    use AI::MXNet::Base;#zip, enumerate, product, bisect_left, pdl_shuffle, assert, check_call, build_param_doc
    use AI::MXNet::Gluon qw(gluon);
    use AI::MXNet::Gluon::NN qw(nn);
    #use Math::MatrixDecomposition qw(eig);
    #Iterators in Perl: https://www.perl.com/pub/2005/06/16/iterators.html/
    #Consult for additional MXNet libraries at https://metacpan.org/dist/AI-MXNet

    
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
    
    #$d2l->use_svg_display();#Generates an .svg $loss file in the subdirectory of this .pl script.

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

    my $top_bottom;
    my $left_right_center;
    my $spacing_value;
    my $height_value;
    #$d2l->set_scatter(0);
    #$d2l->set_keys($top_bottom="top", $left_right_center="left", $spacing_value=1.3, $height_value=1.5);
    #$d2l->plot($pdlx, $pdly, 'x', 'f(x)', \@legend_arr, undef, undef, 'linear', 'linear', undef, $pdlfigsize, undef);
    #print "(Press <RETURN> to continue)"; $a=<>;


    #2.6.1. Basic Probability Theory
    #my $probabilities = mx->nd->ones([6]) / 6;
    #print "probabilities=", $probabilities->aspdl."\n";
    
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

    #$d2l->set_scatter(0);
    #$d2l->set_keys($top_bottom="top", $left_right_center="right", $spacing_value=1.3, $height_value=1.5);
    #$d2l->plot($pdlestimates, undef, 'Groups of experiments', 'Estimated probability', \@legend_arr, undef, undef, 'linear', 'linear', undef, $pdlfigsize, undef);
    #$d2l->{axes}->replot(legend=>"Average probability", with=>"linespoints", linecolor=>'black', linetype=>9, ones($num_rolls) * 0.167);#https://stackoverflow.com/questions/19412382/gnuplot-line-types
    #print "(Press <RETURN> to continue)"; $a=<>;

    #Dear student, place the book translation and test below ...
    
    print "-------------3.2---------------\n";
    #3.2. Linear Regression Implementation from Scratch

    #3.2.1. Generating the Dataset
    #7 - Test code for d2l function 'synthetic_data'
	my $ndtrue_w = mx->nd->array([2, -3.4]);
	my $true_b = 4.2;
    my $num_examples = 1000;
	my ($ndfeatures, $ndlabels) = $d2l->synthetic_data($ndtrue_w ,$true_b, $num_examples);
    #print 'features:', $ndfeatures->slice(0)->aspdl, 'label:', $ndlabels->slice(0)->aspdl;
    
    @legend_arr = (".");
    #$d2l->set_scatter(1);
    #$d2l->set_keys($top_bottom="top", $left_right_center="left", $spacing_value=1.3, $height_value=1.5);
    #$d2l->plot($ndfeatures->slice('X', 1)->aspdl->transpose, $ndlabels->aspdl->transpose, 'x', 'y', \@legend_arr, undef, undef, undef, undef, undef, undef, undef);
    #print "(Press <RETURN> to continue)"; $a=<>;

=pod
    #manually made data iterator
    sub data_iter{
      my ($batch_size, $X, $y) = @_;
      my $num_examples = $X->len;
      my @indices_arr = (0 .. $num_examples - 1);
      # The examples are read at random, in no particular order
      @indices_arr = shuffle(@indices_arr);
      for (my $i=0; $i<$num_examples; $i += $batch_size){
        print ("i=", $i, " num_examples", $num_examples, " batch_size=", $batch_size, "\n");
        my @batch_indices = map { $indices_arr[$_]} $i .. $d2l->min_value(($i + $batch_size, $num_examples)) -1;
        dump @batch_indices;
        #Missing yield like function and slice of the ndarray by @batch_indices.
      }
    }
=cut

    #3.2.2. Reading the Dataset
    #https://mxnet.apache.org/versions/1.8.0/api/perl/docs/tutorials/io
    my $batch_size = 5;
    my $nd_iter = mx->io->NDArrayIter(data=>$ndfeatures, label=>$ndlabels, batch_size=>$batch_size, shuffle=>0);
    
    #for my $batch (@{ $nd_iter }) {
    #  print $batch->data->[0]->aspdl, $batch->label->[0]->aspdl, "\n";
    #}
    #$nd_iter->reset();


    #3.2.3. Initializing Model Parameters
    my $ndw = mx->nd->random_normal(0, 0.01, shape=>[2, 1]);
    my $b = mx->nd->zeros([1]);
    $ndw->attach_grad();
    $b->attach_grad();

       
    #3.2.7. Training
    my $lr = 0.03;
    my $num_epochs = 3;
    my $net  = \&{'d2l::linreg'};#Dynamic Package Name & Subroutine Call 
    my $loss = \&{'d2l::squared_loss'};#https://www.geeksforgeeks.org/packages-in-perl/      https://www.perlmonks.org/?node_id=1008906
    my $ndl;
    my $ndtrain_l;
    
    for my $epoch (1 .. $num_epochs){
      for my $batch (@{ $nd_iter }) {
        my $ndX = $batch->data->[0];
        my $ndy = $batch->label->[0];
        #print "ndX=", $ndX->aspdl, "\n";
        #print "ndy=", $ndy->aspdl, "\n";
        
        # Start recording computation graph with record() section.
        # Recorded graphs can then be differentiated with backward.
        autograd->record(sub {
          $ndl = $loss->($net->($ndX, $ndw, $b), $ndy);
          #print "loss=", $ndl->aspdl, "\n";
        });
        $ndl->backward();

        $d2l->sgd(\$ndw, \$b, $lr, $batch_size);# Update parameters using their gradient
      }
      $ndtrain_l = $loss->($net->($ndfeatures, $ndw, $b), $ndlabels);
      print "Epoch=", $epoch, " loss=",  $ndtrain_l->mean->asscalar, "\n";
      $nd_iter->reset() if $epoch < $num_epochs;#After each epoch, all data have been consumed.
    }

    my $error_w = $ndtrue_w - $ndw->reshape($ndtrue_w->shape);
    my $error_b = $true_b - $b;
    print "Error in estimating w: ", $error_w->aspdl, "\n";
    print "Error in estimating b: ", $error_b->aspdl, "\n";
    
    print "-------------3.3---------------\n";
    #3.3. Concise Implementation of Linear Regression
    #3.3.1. Generating the Dataset
    
    $ndtrue_w = mx->nd->array([2, -3.4]);
	$true_b = 4.2;
    $num_examples = 100;
	($ndfeatures, $ndlabels) = $d2l->synthetic_data($ndtrue_w ,$true_b, $num_examples);


    @legend_arr = (".");
    $d2l->set_scatter(1);
    $d2l->set_keys($top_bottom="top", $left_right_center="left", $spacing_value=1.3, $height_value=1.5);
    $d2l->plot($ndfeatures->slice('X', 1)->aspdl->transpose, $ndlabels->aspdl->transpose, 'x', 'y', \@legend_arr, undef, undef, undef, undef, undef, undef, undef);
    print "(Press <RETURN> to continue)"; $a=<>;
    
    $batch_size = 10;
    #my @data_arrays2 = ($ndfeatures, $ndlabels);
    #my $data_iter = $d2l->load_array2(\@data_arrays2, $batch_size, 1);
    my $data_iter = $d2l->load_array($ndfeatures, $ndlabels, $batch_size, 1);

    #Two flavors of iterators
=pod
    while(defined(my $batch = <$data_iter>)){
      print "data=", $batch->[0]->aspdl, "labels=", $batch->[1]->aspdl, "\n";
    }
    for my $batch (@{ $data_iter }) {
      print "data=", $batch->[0]->aspdl, "labels=", $batch->[1]->aspdl, "\n";
    }
=cut

    #3.3.3. Defining the Model
    #https://gluon.mxnet.io/chapter02_supervised-learning/linear-regression-gluon.html
    #use AI::MXNet::Gluon::NN qw(nn);
    my $net2 = nn->Sequential();
    #we have an input dimension of 2 and an output dimension of 1.
    #https://discuss.mxnet.apache.org/t/why-deferred-initialization/1744
           
    # use net's name_scope to give child Blocks appropriate names.
    $net2->name_scope(sub {
        $net2 = nn->Dense(units=>1, in_units=>2);
    });
    
    #3.3.4. Initializing Model Parameters
    $net2->initialize(mx->init->Normal(0.01));
    print ("\n", $net2->collect_params(), "\n");
    
    #3.3.5. Defining the Loss Function
    $loss = gluon->loss->L2Loss();
    
    #3.3.6. Defining the Optimization Algorithm
    my $trainer = gluon->Trainer($net2->collect_params(), optimizer=>'sgd', optimizer_params=>{ learning_rate => 0.03 });

    #3.3.7. Training
    $num_epochs = 10;
    my @loss_sequence_arr = ();
    for my $epoch (1 .. $num_epochs){
      my $cumulative_loss = 0;
      while(defined(my $batch = <$data_iter>)){
        my $X = $batch->[0];
        my $y = $batch->[1];#->reshape([1, -1])->at(0);
        #print "X=", $X->aspdl;
        #print "y=", $y->aspdl, "\n";
        
        # Start recording computation graph with record() section.
        # Recorded graphs can then be differentiated with backward.

        autograd->record(sub {
          #print "inside autograd\n";
          my $y_hat = $net2->($X);
          #print "y_hat=", $y_hat, $y_hat->aspdl, "\n";
          $ndl = $loss->($y_hat, $y);
          #print "loss=", $ndl->aspdl, "\n";
        });
        $ndl->backward();

        $trainer->step($batch_size);# Update parameters using their gradient
        $cumulative_loss += mx->nd->mean($ndl)->asscalar();
      }
      $ndtrain_l = $loss->($net2->($ndfeatures), $ndlabels);
      print "Epoch=", $epoch, " loss=",  $ndtrain_l->mean->asscalar, "\n";
      push @loss_sequence_arr, $cumulative_loss;
    }

    $ndw = $net2->weight->data()->at(0);
    $b = $net2->bias->data()->asscalar;
    print "w: ", $ndw->aspdl, " true_w: ", $ndtrue_w->aspdl, "\n";
    print "b: ", $b, " true_b: ", $true_b, "\n";

    print "Error in estimating w: ", ($ndtrue_w - $ndw)->aspdl, "\n";
    print "Error in estimating b: ", $true_b - $b, "\n";

    #Plotting the learning curve.
    @legend_arr = ("Learning curve");
    
    my $pdlX = sequence($num_epochs) + 1;
    my $pdlloss_sequence = pdl \@loss_sequence_arr;
    $d2l->set_scatter(0);
    $d2l->set_keys($top_bottom="top", $left_right_center="center", $spacing_value=1.3, $height_value=1.5);
    $d2l->plot($pdlX, $pdlloss_sequence, 'Epoch', 'Average loss', \@legend_arr, undef, undef, undef, undef, undef, undef, undef);
    print "(Press <RETURN> to continue)"; $a=<>;
    
    
    
    
    
    