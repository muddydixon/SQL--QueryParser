package SQL::QueryParser::Calculator;
use strict;
use warnings;
use Carp;

my @allowedOnOperator = (
    "\t", "\n", "\r", " ", ",", "(", ")", "_", "'", "\""
    );
my @allowedOnOther = (
    "\t", "\n", "\r", " ", ",", "(", ")", "<", ">",
    "*", "+", "-", "/", "|", "&", "=", "!", ";"
    );

sub new {
    my $self = shift;
    return bless +{
        
    }, $self;
}

sub printPos {
    my $self = shift;
    my ($text, $sql, $charPos, $key, $parsed, $backtracking) = @_;
}

sub setPositionsWithinSQL {
    my $self = shift;
    my $sql = shift;
    my $parsed = shift;

    my $charPos = 0;
    my $backtracking = [];

    $self->lookForBaseExpression($sql, $charPos, $parsed, 0, $backtracking);
    return $parsed;
}

sub findPositionWithinString {
    my $self = shift;
    my $sql = shift;
    my $value = shift;
    my $expr_type = shift;

    my $offset = 0;
    my $ok = 0;

    while(1){
        my $pos = $offset + index(substr($sql, $offset), $value);
        last if $pos < $offset;

        my $before = "";
        if ($pos > 0){
            $before = substr $sql, $pos - 1, 1;
        }
        my $after = "";
        if(substr($sql, $pos + length $value, 1) ne ""){
            $after = substr($sql, $pos + length $value, 1);
        }

        if($expr_type eq "operator"){
            $ok = ($before eq "" or &inArray($before, @allowedOnOperator)) or
                &toLowerCase($before) =~ /^[a-z]$/ or
                $before =~ /^\d$/;
            $ok = $ok and ($after eq "" or &inArray($after, @allowedOnOperator)) or
                &toLowerCase($after) =~ /^[a-z]$/ or
                $before =~ /^\d$/ or $after eq "?" or $after eq "@";


            if(!$ok){
                $offset = $pos + 1;
                next;
            }

            last;
        }

        $ok = ($before eq "" or &inArray($before, @allowedOnOther));
        $ok = $ok and ($after eq "" or &inArray($after, @allowedOnOther));

        if($ok){
            last;
        }

        $offset = $pos + 1;
    }
    return $pos;
}

sub lookForBaseExpression {
    my $self = shift;
    my ($sql, &$charPos, &$parsed, $key, &$backtracking) = @_;

    if($key !~ /^\d+$/){
        if(($key eq "UNION" or $key eq "UNION ALL") or ($key eq "expr_type" and $parsed eq "expression") or
           ($key eq "expr_type" and $parsed eq "subquery") or
           ($key eq "expr_type" and $parsed eq "bracket_expression") or
           ($key eq 'expr_type' and $parsed eq 'table_expression') or
           ($key eq 'expr_type' and $parsed eq 'record') or
           ($key eq 'expr_type' and $parsed eq 'in-list') or
           ($key eq 'alias' and $parsed != 0)) {
            push @$backtracking, $charPos;
        }
    }
}


sub toLowerCase {
    my $str = shift;
    $str =~ tr/[A-Z]/[a-z/;
    return $str;
}

sub inArray {
    my $char = shift;
    my @array = @_;

    foreach my $a (@array){
        if("$a" eq "$char"){
            return 1;
        }
    }
    return 0;
}
1;
