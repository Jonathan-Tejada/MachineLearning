#!/usr/bin/perl -w

#Place this library at a visible Perl subdirectory, such as /home/your_user_name/perl5/lib/perl5/x86_64-linux/d2l.pm

package d2l;
    use vars qw/$VERSION/;
    $VERSION = '0.01';
    
    use strict;
    use warnings;
    use Encode;
    use utf8;
    use Config;
    binmode STDOUT, ":utf8";
    binmode STDERR, ":utf8";
    use Data::Dump qw(dump);
    use PDL;#https://manpath.be/f32/1/PDL::Scilab
    use PDL::LinearAlgebra;
    use PDL::Graphics::Gnuplot;#https://metacpan.org/pod/PDL::Graphics::Gnuplot#3D-plotting   https://www.youtube.com/watch?v=hUXDQL3rZ_0   https://metacpan.org/release/ETJ/PDL-Graphics-Gnuplot-2.017/source/demo.pl   Gnuplot book: http://www.gnuplot.info/docs_5.4/Gnuplot_5_4.pdf
    use PDL::Constants;
    use Scalar::Util qw(blessed reftype);
    use Inline 'Pdlpp'; # the actual code is in the __Pdlpp__ block below
    #use Math::MatrixDecomposition qw(eig);
    #use AI::MXNet qw(mx);
    #use AI::MXNet qw(nd);
    #use AI::MXNet::AutoGrad qw(autograd);
    #use AI::MXNet::Base;#zip, enumerate, product, bisect_left, pdl_shuffle, assert, check_call, build_param_doc
    #Consult for additional MXNet libraries at https://metacpan.org/dist/AI-MXNet
    
    #This file will be constantly updated.
    
    sub new {
    my ($self) = @_;
      return $self, bless {
        pi=> 4*atan2(1,1),
        debug => 0,
        trim => sub { return 0 + sprintf '%.3f', shift; },
        axes => gpwin( 'x11', enhanced=>1)
      }, shift;
    }
   
   
    sub zippdl (&@){#Each pdl is a one dimensional row vector
      my $self = shift;
      my $min;
      $min = $min && $_->getdim(0) > $min ? $min : $_->getdim(0) for @_;#Obtaining the shortest pdl's dimension
      for my $row (0 .. $min-1){ $self->(map $_->at($row), @_) }
    }
    
    sub concat_transpose (&@){
      my $self = shift;
      my $min;
      $min = $min && $_->getdim(0) > $min ? $min : $_->getdim(0) for @_;#Obtaining the shortest pdl's dimension
      my @tuples_arr = map { my $row = $_;#Outer map is evaluated first, so $row is known at the beginning.
                            [map { #my $col = $_;#Middle map is evaluated second, so $col is known after row.
                                  #print $_."\n";#$_ is an individual pdl
                                  $_->at($row);
                            } @_];#Closing bracket here to get all columns together into the same row of the output array.
                        } (0 .. $min -1);
      return pdl @tuples_arr;
    }

    # Defined in file: ./chapter_preliminaries/calculus.md
    sub use_svg_display{
      #Use the svg format to display a Gnuplot. #See page 283 of Gnuplot book
      my $self = shift;
      $self->{axes} = gpwin( 'svg', enhanced=>1);# See pdl> PDL::Graphics::Gnuplot::terminfo( svg );  https://metacpan.org/dist/PDL-Graphics-Gnuplot/view/README.pod#output
      print "The .svg files are placed at ".`pwd`."Look for a file name like Plot-1.svg\n";
    }

    sub use_default_display{
      #Use the x11 format to display a Gnuplot. See pdl> PDL::Graphics::Gnuplot::terminfo;
      my $self = shift;
      $self->{axes} = gpwin( 'x11', enhanced=>1);# See pdl> PDL::Graphics::Gnuplot::terminfo( x11 );
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    sub set_figsize{
      #width and hight are given in pixels for .svg files by default. See pdl> PDL::Graphics::Gnuplot::terminfo( svg ); 
      #Set the figure size for Gnuplot. The unit depends on the current terminal.
      my ($self, $pdlfigsize) = @_;
      if ($self->{axes}->{terminal} eq "svg"){#Test for precaution, given the measurement units for each terminal is different.
        $self->{axes} = gpwin( $self->{axes}->{terminal}, size=>[$pdlfigsize->at(0), $pdlfigsize->at(1)]);# See pdl> PDL::Graphics::Gnuplot::terminfo( svg );  https://metacpan.org/dist/PDL-Graphics-Gnuplot/view/README.pod#output
      }elsif ($self->{axes}->{terminal} eq "x11"){#X11 default unit would freeze the system if 640x480 is input to this function.
        $self->{axes} = gpwin( $self->{axes}->{terminal}, size=>[$pdlfigsize->at(0), $pdlfigsize->at(1), 'px']);# So we set X11 unit to pixels instead.
      }
    }    

    # Defined in file: ./chapter_preliminaries/calculus.md
    sub set_keys{
      #Set the figure size for Gnuplot.
      my ($self, $top_bottom, $left_right_center, $spacing_value, $height_value) = @_;
      $self->{axes}->options (key=>"$top_bottom $left_right_center spacing $spacing_value height $height_value");# See pages 156-158 of Gnuplot book
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    sub set_axes{
      #Set the axes for Gnuplot
      my ($self, $axes, $xlabel, $ylabel, $pdlxlim, $pdlylim, $xscale, $yscale) = @_;
      $axes->options (xlabel=>"$xlabel") if defined $xlabel;#. See page 172 of Gnuplot book
      $axes->options (ylabel=>"$ylabel") if defined $ylabel;
      #$self->{axes}->options (size=>"$xscale, $yscale");# See pages 194 and 283 of Gnuplot book. Default is 'linear' scale. There is also 'logscale', etc.
      $axes->options (xrange=>$pdlxlim) if defined $pdlxlim;# Sets the limits of the current axes. # See page 214 of Gnuplot book.
      $axes->options (yrange=>$pdlylim) if defined $pdlylim;# It is a range tuple such as $pdlyrange = pdl [0, 1.5];
      #Legends belog to the plot function instead, as it labels each curve in the plot.
      $axes->options (grid=>["xtics","ytics"]);#See https://metacpan.org/dist/PDL-Graphics-Gnuplot/view/README.pod#POs-for-axes,-grids,-&-borders
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    # Returns 1 if `X` (NDArray or PDL) has 1 axis
    # https://stackoverflow.com/questions/36851474/how-can-i-check-if-a-perl-variable-is-in-pdl-format-i-e-is-a-piddle
    sub has_one_axis{
      my ($X) = @_;
      if (reftype($X) eq "ARRAY"){
        print "X is a list which is not yet handled.\n";
        return 0;
      }if ($X->isa("PDL")){
        return (!$X->isempty && $X->getdim(1) == 1);
      }elsif($X->isa("AI::MXNet::NDArray")){
        return ($X->ndim == 1);
      }
      return 0;
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    sub plot{
      #Plot data points.
      my ($self, $X, $Y,     $xlabel,     $ylabel, $legend_arr_ref, $pdlxlim, $pdlylim,  $xscale,         $yscale,         $fmts,                          $pdlfigsize,          $axes) = @_;
                #(X, Y=None, xlabel=None, ylabel=None, legend=None, xlim=None, ylim=None, xscale='linear', yscale='linear', fmts=('-', 'm--', 'g-.', 'r:'), figsize=pdl[3.5, 2.5], axes=None)

      if (!defined $Y){
        $Y = $X;#Move  X to Y
        $X = pdl [];#Clean X
      }
      
      #Standardizing into pdl if parameters are AI::MXNet::NDArray
      my $pdlX = $X->isa("AI::MXNet::NDArray") ? $X->aspdl : $X;
      my $pdlY = $Y->isa("AI::MXNet::NDArray") ? $Y->aspdl : $Y;
      #print $pdlX."\n";
      #print $pdlY."\n";
      
      #Building legends for each curve as a Perl array because it is made of strings.
      my @legend_arr = ();
      for (my $i=0; $i < $pdlY->getdim(1); $i++){
        push @legend_arr, defined @{$legend_arr_ref}[$i] ? @{$legend_arr_ref}[$i] : "Legend for curve ".($i+1);
      }

      $self->set_figsize($pdlfigsize);
      $axes = $self->{axes} if !defined $axes;
      
      $pdlxlim = pdl [(min $pdlX), (max $pdlX)] if (!defined $pdlxlim && !$pdlX->isempty);#->getdim(0) > 0
      $pdlylim = pdl [(min $pdlY), (max $pdlY)] if (!defined $pdlylim && !$pdlY->isempty);
      #print $pdlxlim."\n" if defined $pdlxlim;
      #print $pdlylim."\n" if defined $pdlylim;
      
      if (!$pdlX->isempty && $pdlX->getdim(1) != $pdlY->getdim(1)){
        $pdlX = $pdlX->dummy(1, $pdlY->getdim(1));#X = X * len(Y)
        #print $pdlX, "\n";
      }
      
      #Checking whether both piddles have the same shape.
      if (!$pdlX->isempty && $pdlX->dims != $pdlY->dims){
        print "pdlX->shape=", $pdlX->shape."\n";
        print "pdlY->shape=", $pdlY->shape."\n";
        die "Both pdlX and pdlY must have the same shapes.\n";
      }
    
      #Iterates and returns tuple by tuple
      for (my $i=0; $i<$pdlY->getdim(1); $i++) {
        my $x = $pdlX->slice(":, $i");
        my $y = $pdlY->slice(":, $i");
        my $legend = $legend_arr[$i];
        #print "x=", $x, "\n";
        #print "y=", $y, "\n";
        if ($i==0){
          if ($pdlX->isempty){$axes->plot(legend=>"$legend", with=>"points", $y);}
          else{$axes->plot(legend=>"$legend", with=>"lines", $x, $y);}
        }else{
          if ($pdlX->isempty){$axes->replot(legend=>"$legend", with=>"points", $y);}
          else{$axes->replot(legend=>"$legend", with=>"line", $x, $y);}#linespoints
        }
      }

      $self->set_axes($axes, $xlabel, $ylabel, $pdlxlim, $pdlylim, $xscale, $yscale);
      $self->set_keys(my $top_bottom="top", my $left_right_center="left", my $spacing_value=1.3, my $height_value=1.5);
      $axes->replot();
    }

    
    
    #Estudiante: agregue a partir de este punto y antes de __DATA__ las funciones traducidas de Python3 a esta librería d2l para Perl. Mantener el mismo orden de las definiciones encontrados la librería d2l de Python3.
    #En el archivo test_dl.pl ingrese el código de prueba utilizado para testear la función traducida a Perl.
    
=pod
#To be revised under PDL/Komodo/Command line interpreter
#def synthetic_data/
sub synthetic_data{
    my($w,$b,$num_examples)=@_;   
    $X=mx->nd->random_normal(0,1,shape=>[$num_examples,2]);
    $y=mx->nd->dot($X,$w)+$b;
    $y+=mx->nd->random_normal(0,0.01,shape=>$y->aspdl->shape);
    $y2=$y->reshape([-1,1]);
    return $X,$y2;
}

#def linreg/
sub linreg{
    my($X,$w,$v)=@_;
    return mx->nd->dot($X,$w)+$b;
}

#def squared_loss/
sub squared_loss{
    my($y_hat,$y)=@_;
    $y2=$y->reshape([-1,1]);
    return ($y_hat-$y->reshape([$y_hat->shape]))**2/2;
}
    
#def sgd
sub sgd{#@save
    my($params,$lr,$batch_size)=@_;
    my $params2=$params;
    for ($i=0;$i<$params->size();$i++){
        $params2[$i]=$params2[$i]-$lr*$params2->grad()/$batch_size;
    }
}  
=cut   
    


__DATA__

#2 - Example of PDL PreProcessor functions for creating new pdl functions.
#https://master.dl.sourceforge.net/project/pdl/PDL/2.4.10/PDL-Book-20120205.pdf
#Refer to Chapter 11: The PDL PreProcessor
    
__Pdlpp__
pp_def('inc',
       Pars => 'i();[o] o()',
       Code => '$o() = $i() + 1;',
      );

pp_def('tcumul',
       Pars => 'in(n);[o] mul()',
       Code => '$mul() = 1;
                loop(n) %{
                  $mul() *= $in();
                %}',
      );

pp_def('my_sumover',
        Pars=>'input(n);[o]sum()',
        Code=>q{
                 $sum()=0;
                 loop(n)%{
                   $sum()+=$input();
                 %}
         }
      );

1;
