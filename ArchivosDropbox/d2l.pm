#!/usr/bin/perl -w

#Place this library at a visible Perl subdirectory, such as /home/your_user_name/perl5/lib/perl5/x86_64-linux/d2l.pm

package d2l;
    use vars qw/$VERSION/;
    $VERSION = '0.03';#2021-06-20
    
    use strict;
    use warnings;
    use Scalar::Util qw(blessed reftype);
    use PDL;#https://manpath.be/f32/1/PDL::Scilab
    use PDL::Graphics::Gnuplot;#https://metacpan.org/pod/PDL::Graphics::Gnuplot#3D-plotting   https://www.youtube.com/watch?v=hUXDQL3rZ_0   https://metacpan.org/release/ETJ/PDL-Graphics-Gnuplot-2.017/source/demo.pl   Gnuplot book: http://www.gnuplot.info/docs_5.4/Gnuplot_5_4.pdf
    use PDL::Constants;
    use PDL::LinearAlgebra;
    use Inline 'Pdlpp'; # the actual code is in the __Pdlpp__ block below
    
    #This file will be constantly updated.
    
    sub new {
    my ($self) = @_;
      return $self, bless {
        pi=> 4*atan2(1,1),
        debug => 0,
        trim => sub { return 0 + sprintf '%.3f', shift; },
        axes => gpwin( 'x11', enhanced=>1),
        scatter => "lines"
      }, shift;
    }

    sub min_value{#Minimun value of a Perl unidimensional list. 
      my ($self, @list) = @_;
      my $min = $list[0];
    
      foreach my $value (@list){
        $min = $value if ($value < $min);
      }
    
      return $min;
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
    sub use_svg_display{ #@save
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
    sub set_figsize{ #@save
      #width and hight are given in pixels for .svg files by default. See pdl> PDL::Graphics::Gnuplot::terminfo( svg ); 
      #Set the figure size for Gnuplot. The unit depends on the current terminal.
      my ($self, $pdlfigsize) = @_;
      
      $pdlfigsize = pdl [640, 480] if !defined $pdlfigsize;
      
      if ($self->{axes}->{terminal} eq "svg"){#Test for precaution, given the measurement units for each terminal is different.
        $self->{axes} = gpwin( $self->{axes}->{terminal}, size=>[$pdlfigsize->at(0), $pdlfigsize->at(1)]);# See pdl> PDL::Graphics::Gnuplot::terminfo( svg );  https://metacpan.org/dist/PDL-Graphics-Gnuplot/view/README.pod#output
      }elsif ($self->{axes}->{terminal} eq "x11"){#X11 default unit would freeze the system if 640x480 is input to this function.
        $self->{axes} = gpwin( $self->{axes}->{terminal}, size=>[$pdlfigsize->at(0), $pdlfigsize->at(1), 'px']);# So we set X11 unit to pixels instead.
      }
    }    

    # Defined in file: ./chapter_preliminaries/calculus.md
    sub set_keys{
      #Set the configuration for the plot labels.
      my ($self, $top_bottom, $left_right_center, $spacing_value, $height_value) = @_;
      $self->{axes}->options (key=>"$top_bottom $left_right_center spacing $spacing_value height $height_value");# See pages 156-158 of Gnuplot book
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    sub set_axes{ #@save
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
    sub has_one_axis{ #@save
      my ($self, $X) = @_;
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
    
    sub set_scatter{
        my ($self, $value) = @_;
        $value = $value == 1 ? "points" : "lines";
        $self->{scatter} = $value;
    }

    sub get_scatter{
        my ($self) = @_;
        return $self->{scatter};
    }
    
    # Defined in file: ./chapter_preliminaries/calculus.md
    sub plot{ #@save
      #Plot data points.
      my ($self, $X, $Y,     $xlabel,     $ylabel, $legend_arr_ref, $pdlxlim, $pdlylim,  $xscale,         $yscale,         $fmts,                          $pdlfigsize,            $axes) = @_;
                #(X, Y=None, xlabel=None, ylabel=None, legend=None, xlim=None, ylim=None, xscale='linear', yscale='linear', fmts=('-', 'm--', 'g-.', 'r:'), figsize=pdl[3.5, 2.5], axes=None)

      my $key_config = "".$self->{axes}->options->{key}->[0];#Saving key configuration to use at the end, otherwise this info is lost during axis configuration.
      
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
      
      #linetype = 1: x
      #linetype = 2: X
      #linetype = 3: big asteriscs
      #linetype = 4: empty squares
      #linetype = 5: filled squares
      #linetype = 6: empty circles
      #linetype = 7: small asteriscs
      #linetype = 8: empty triangles
      #linetype = 9: +
    
      #Iterates and returns tuple by tuple
      for (my $i=0; $i<$pdlY->getdim(1); $i++) {
        my $x = $pdlX->slice(":, $i");
        my $y = $pdlY->slice(":, $i");
        my $legend = $legend_arr[$i];
        #print "x=", $x, "\n";
        #print "y=", $y, "\n";
        if ($i==0){
          if ($pdlX->isempty){$axes->plot(legend=>"$legend", with=>"points", $y);}
          else{$axes->plot(legend=>"$legend", with=>"$self->{scatter}", linecolor=>'blue', linetype=>5, $x, $y);}#lines
        }else{
          if ($pdlX->isempty){$axes->replot(legend=>"$legend", with=>"points", $y);}
          else{$axes->replot(legend=>"$legend", with=>"line", $x, $y);}#linespoints
        }
      }

      $axes->options (key=>"$key_config") if defined $key_config;
      $self->set_axes($axes, $xlabel, $ylabel, $pdlxlim, $pdlylim, $xscale, $yscale);
      $axes->replot();
    }
    
    
    #3.2.1. Generating the Dataset
    #def synthetic_data/
    sub synthetic_data{ #@save
        #Generate y = Xw + b + noise.
        my($self, $w, $b, $num_examples) = @_;
        #mx->random->seed(42); #Fix the seed for reproducibility (debugging purposes to make results comparable with Python)
        my $X = mx->nd->random_normal(0, 1, shape=>[$num_examples, $w->len]);#$true_w->len replaces 2
        my $y = mx->nd->dot($X, $w) + $b;
        $y += mx->nd->random_normal(0, 0.01, shape=>$y->shape);#Noise
        return ($X, $y->reshape([-1, 1]));#External parenthesis to make a Perl array out of the variables being returned.
    }
    
    #3.2.4. Defining the Model
    #def linreg/
    sub linreg{ #@save
        #The linear regression model.
        my($X, $w, $b)= @_;
        return mx->nd->dot($X, $w) + $b;
    }
    
    #3.2.5. Defining the Loss Function
    #def squared_loss/
    sub squared_loss{ #@save
       #Squared loss.
       my ($y_hat, $y) = @_;
       return ($y_hat - $y->reshape($y_hat->shape))**2 / 2;
    }
    
    #3.2.6. Defining the Optimization Algorithm
    sub sgd{ #@save
      #Minibatch stochastic gradient descent.
      my ($self, $w, $b, $lr, $batch_size) = @_;  #@save
       #Minibatch stochastic gradient descent.
       #print "wnd before=", $$w->aspdl, "\n";
       #print "ndb before=", $$b->aspdl, "\n";
       
       $$w = $$w - $lr * $$w->grad() / $batch_size;
       $$b = $$b - $lr * $$b->grad() / $batch_size;
       
       $$w->attach_grad();
       $$b->attach_grad();
    
       #print "wnd after=", $$w->aspdl, "\n";
       #print "ndb after=", $$b->aspdl, "\n";
    }

    #3.3.2. Reading the Dataset
    sub load_array{ #@save
      #Construct a Gluon data iterator.
      my ($self, $X, $y, $batch_size, $is_train) = @_;
      my $dataset = gluon->data->ArrayDataset(data=>$X, label=>$y);
      return gluon->data->DataLoader($dataset, batch_size=>$batch_size, shuffle=>$is_train);
    }
    
    sub load_array2{ #@save
      #Construct a Gluon data iterator.
      my ($self, $data_arrays_ref, $batch_size, $is_train) = @_;
      my $dataset = gluon->data->ArrayDataset(data=>@{$data_arrays_ref}[0], label=>@{$data_arrays_ref}[1]);
      return gluon->data->DataLoader($dataset, batch_size=>$batch_size, shuffle=>$is_train);
    }

    #Alternatively, but inefficiently we could concatenate data rows with labels to form nd_rows and build a simple Perl array.
    #my @data_arrays = map {mx->nd->concatenate([$X->[$_], $y->[$_]]) } 0 .. @{$X} -1;
    #foreach $ndelem (@data_arrays){p $ndelem->aspdl;}
    
    #Revisiones y correcciones realizadas por el docente hasta aquí.

    #Recomendaciones y procedimientos didácticos para traducir el código:
    #0 - Descargue los archivos book.pl y d2l.pm actualizados.
    #1 - Depure el código para aprender los detalles de programación.
    #2 - Consulte los enlaces presentes a lo largo del código de los archivos book.pl o d2l.pm para obtener más información sobre ciertos comandos.
    #3 - Al escribir un código,  siempre poner un espacio en blanco después de toda coma, operador de concatenación “.”, operador de asignación “=”, entre otros, al listar los parámetros. No ponga todo unido porque se ve el comando como una sola palabra, o ilegible para la comprehensión de quienes revisan.
    #4 - Tome el formato del código publicado como referencia para mantener la consistencia de formatos. Mantenga las frases que explican que se hace en cada bloque de código. Mantenga la información de las secciones del libro en donde se encuentra el bloque de código.
    #5 - Depure los errores de sintaxis de su código antes de actualizar los archivos book.pl o d2l.pm. Utilice el revisor gramatical de la herramienta Komodo.
    #6 - Ejecute el código desde la consola con $ perl book.pl para asegurar su funcionamiento. Dejar comentado (=pod =cut) todo bloque de código que no aún funcione correctamente para revisión.

    #Estudiante: agregue a partir de este punto y antes de __DATA__ las funciones traducidas de Python3 a esta librería d2l para Perl. Mantener el mismo orden de las definiciones encontrados la librería d2l de Python3.
    #En el archivo test_dl.pl ingrese el código de prueba utilizado para testear la función traducida a Perl.
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
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
