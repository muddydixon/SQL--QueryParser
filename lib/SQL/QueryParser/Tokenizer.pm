package SQL::QueryParser::Tokenizer;
use strict;
use warnings;
use Carp;

use SQL::QueryParser::Constant qw/reserved functions/;

my @splitters = (
    "\r\n", "!=", ">=", "<=", "<>", "\\", "&&",
    ">", "<", "|", "=", "^", "(", ")", "\t", "\n",
    "'", "\"", "`", ",", "@", " ", "+", "-", "*", "/", ";"
    );

my %splitters = ();
map{ $splitters{$_} = 1; } @splitters;

my $splitterMaxLength = 0;
foreach my $splitter (@splitters){
    $splitterMaxLength =
        $splitterMaxLength > length $splitter ?
        $splitterMaxLength :
        length $splitter;
}

sub new {
    my $self = shift;
    return bless +{
        tokens => []
    }, $self;
}

sub split {
    my $self = shift;
    my $sql = shift;

    my $pos = 0;
    my $token = "";

    POS: while($pos < length $sql){
        for(my $i = $splitterMaxLength; $i > 0; $i--){
            my $substr = substr $sql, $pos, $i;

            if(exists $splitters{$substr}){

                if($token ne ""){
                    push @{$self->{tokens}}, $token;
                }
                
                push @{$self->{tokens}}, $substr;
                $pos += $i;

                $token = "";
                next POS;
            }
        }
        $token .= substr($sql, $pos, 1);
        $pos++;
    }
    if($token ne ""){
        push @{$self->{tokens}}, $token;
    }

    $self->concatEscapeSequences();
    $self->balanceBackticks();
#     $self->concatColReferences();
    $self->balanceParenthesis();
    $self->balanceComments();

    return $self->{tokens};
}


sub concatEscapeSequences {
    my $self = shift;
    my $i = 0;
    
    while($i < scalar @{$self->{tokens}}){
        my $token = $self->{tokens}[$i];
        if($token =~ /\\$/){
            if(defined $self->{tokens}[$i + 1]){
                $self->{tokens}[$i] .= $self->{tokens}[$i + 1];
                splice @{$self->{tokens}}, $i + 1, 1;
            }
        }else{
            $i++;
        }
    }
}

sub balanceBackticks {
    my $self = shift;
    my $i = 0;
    
    while($i < scalar @{$self->{tokens}}){
        unless(defined $self->{tokens}[$i]){
            $i++;
            next;
        }

        my $token = $self->{tokens}[$i];
        if($token eq "'" or $token eq "\"" or $token eq "`"){
            $self->balanceCharacter($i, $token);
        }
        $i++;
    }
}

sub balanceCharacter {
    my $self = shift;
    my $idx = shift;
    my $char = shift;
    my $i = $idx + 1;

    while($i < scalar @{$self->{tokens}}){
        unless(defined $self->{tokens}[$i]){
            $i++;
            next;
        }
        last if $self->{tokens}[$i] eq $char;
        $i++;
    }

    $self->{tokens}[$idx] = join("", @{$self->{tokens}}[$idx..$i]);
    splice @{$self->{tokens}}, $idx + 1, $i - $idx;
}

sub concatColReferences {
    my $self = shift;
    my $i = 0;

    while($i < scalar @{$self->{tokens}}){
        unless(defined $self->{tokens}[$i]){
            $i++;
            next;
        }

        my $token = $self->{tokens}[$i];
        if($token =~ /^\./){
            
        }
        $i++;
    }
}

sub balanceParenthesis {
    my $self = shift;
    my $i = 0;
    my $tokenSize = scalar @{$self->{tokens}};

    while($i < $tokenSize){
        unless(defined $self->{tokens}[$i]){
            $i++;
            next;
        }
        
        my $token = $self->{tokens}[$i];
        unless($token eq "("){
            $i++;
            next ;
        }

        my $cnt = 1;
        my $n = 0;
        for($n = $i + 1; $n < $tokenSize; $n++){
            
            $cnt++ if $self->{tokens}[$n] eq "(";
            $cnt-- if $self->{tokens}[$n] eq ")";

            $self->{tokens}[$i] .= $self->{tokens}[$n];
            splice @{$self->{tokens}}, $n, 1;

            if($cnt == 0) {
                $n++;
                last;
            }else{
                $n--;
            }
        }
        $i = $n;
    }
}

sub balanceComments {
    my $self = shift;
    my $i = 0;
    my $inComment = -1;

    while($i < scalar @{$self->{tokens}}){
        unless(defined $self->{tokens}[$i]){
            $i++;
            next;
        }

        my $token = $self->{tokens}[$i];
        
        if($inComment == -1 and $token eq "/" and $self->{tokens}[$i + 1] and $self->{tokens}[$i + 1] eq "*"){
            carp "inComment = $inComment, token = $token, token[\$i + 1] = $self->{tokens}[$i + 1]";
            $inComment = $i;
            $self->{tokens}[$i] = "/*";
            $i++;
            splice @{$self->{tokens}}, $i, 1;
            next;
        }

        if($inComment > -1 and $token eq "*" and $self->{tokens}[$i + 1] and $self->{tokens}[$i + 1] eq "/"){
            $self->{tokens}[$inComment] .= "*/";
            splice @{$self->{tokens}}, $i, 2;
            $inComment = -1;
            next;
        }
        
        if($inComment > -1){
            $self->{tokens}[$inComment] .= $self->{tokens}[$i];
            splice @{$self->{tokens}}, $i, 1;
            next;
        }

        $i++;
    }
}

1;
