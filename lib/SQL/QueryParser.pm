package SQL::QueryParser;

use 5.006;
use strict;
use warnings;

use SQL::QueryParser::Constant;
use SQL::QueryParser::Tokenizer;
use SQL::QueryParser::Calculator;

use Switch;

=head1 NAME

SQL::QueryParser - The great new SQL::QueryParser!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SQL::QueryParser;

    my $foo = SQL::QueryParser->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
    my $self = shift;

    return bless +{
        tokenizer => new SQL::QueryParser::Tokenizer()
    }, $self;
}

=head2 function2

=cut

sub parse {
    my $self = shift;
    my $sql = shift;
    my $pos = shift || -1;

    my $tokens = [];
    my $queries = {};
    
    $tokens = $self->{tokenizer}->split($sql);
    $queries = $self->processUnion($tokens);

    if(!$self->isUnion($queries)){
        # 0ってなんだ？0って・・・
        $queries = $self->processSQL($queries->{0});
    }

    if($pos){
        my $calculator = new SQL::QueryParser::Calculator();
        $queries = $calculator->setPositionsWithinSQL($sql, $queries);
    }

    return ($self->{parsed} = $queries);
}

sub processUnion {
    my $self = shift;
    my $inputTokens = shift;
    my $outputTokens = [];
    my $skipUntilToken = "";
    my $unionType = "";
    my $queries = {};

    foreach my $key (0..scalar @$inputTokens - 1){
        my $token = $inputTokens->[$key];

        $token = &trim($token);
        
        next if $token eq "";
        if(&toUpperCase($token) eq $skipUntilToken){
            $skipUntilToken = "";
            next;
        }

        if(&toUpperCase($token) ne "UNION"){
            push @$outputTokens, $token;
            next;
        }

        $unionType = "UNION";

        foreach my $i ($key + 1..scalar @$inputTokens - 1){
            next if(&trim($inputTokens->[$i]) eq "");
            last if(&toUpperCase(&trim($inputTokens->[$i])) ne "ALL");

            $skipUntilToken = "ALL";
            $unionType = "UNION ALL";
        }
        $queries->{$unionType} = [] unless exists $queries->{$unionType};
        push @{$queries->{$unionType}}, $outputTokens;
        $outputTokens = [];
    }
    
    if(scalar @{$outputTokens} != 0){
        if(defined $unionType){
            $queries->{$unionType} = [] unless exists $queries->{$unionType};
            push @{$queries->{$unionType}}, $outputTokens;
        }else{
            # なんか、ユニークならいいらしいよ
            $queries->{&maxNumericKey($queries) + 1} = $outputTokens;
        }
    }
    # for MySQL
#     $self->processMySQLUnion(%queries);
    return $queries;
}

sub processMySQLUnion {
    my $self = shift;
    my $queries = shift;
}

sub isUnion {
    my $self = shift;
    my $queries = shift;
    foreach my $unionType ("UNION", "UNION ALL"){
        if(defined $queries->{$unionType}){
            return 1;
        }
    }
    return 0;
}

sub processSQL {
    my $self = shift;
    my $tokens = shift || [];

    my $prev_category = "";
    my $token_category = "";
    my $skip_next = 0;
    my $out = {};


    TOKEN: for(my $i = 0; $i < scalar @{$tokens}; $i++){
        my $token = $tokens->[$i];
        my $trimedToken = &trim($token);
        if($trimedToken ne "" and $trimedToken =~ /^\(/ and $token_category eq ""){
            $token_category = "SELECT";
        }

        if($skip_next){
            if($trimedToken eq ""){
                if($token_category ne ""){
                    $out->{$token_category} = [] unless exists $out->{$token_category};
                    push @{$out->{$token_category}}, $token;
                }
                next;
            }
            $token = "";
            $trimedToken = "";
            $skip_next = 0
        }

        my $upperedToken = &toUpperCase($trimedToken);
        switch($upperedToken){
            case "SELECT" {}
            case "ORDER" {}
            case "LIST" {}
            case "SET" {}
            case "DUPLICATE" {}
            case "VALUES" {}
            case "GROUP" {}
            case "ORDER" {}
            case "HAVING" {}
            case "WHERE" {}
            case "RENAME" {}
            case "CALL" {}
            case "PROCEDURE" {}
            case "FUNCTION" {}
            case "DATABASE" {}
            case "SERVER" {}
            case "LOGFILE" {}
            case "DEFINER" {}
            case "RETURNS" {}
            case "TABLESPACE" {}
            case "TRIGGER" {}
            case "DATA" {}
            case "DO" {}
            case "PLUGIN" {}
            case "FROM" {}
            case "FLUSH" {}
            case "KILL" {}
            case "RESET" {}
            case "START" {}
            case "STOP" {}
            case "PURGE" {}
            case "EXECUTE" {}
            case "PREPARE" {}
            case "DEALLOCATE" {
                if ($trimedToken eq "DEALLOCATE") {
                    $skip_next = 1;
                }
                if ($token_category == "PREPARE" and $upperedToken == "FROM") {
                    next TOKEN;
                }
                
                $token_category = $upperedToken;
                last;
            }
            case "EVENT" {
                if ($prev_category eq "DROP" or $prev_category eq "ALTER" or $prev_category eq "CREATE") {
                    $token_category = $upperedToken;
                }    
                last;
            }
            case "PASSWORD" {
                if ($prev_category eq "SET") {
                		$token_category = $upperedToken;
                }
                last;    
            }
            case "INTO" {
                if ($prev_category eq "LOAD") {
                    $out->{$prev_category} = [] unless exists $out->{$prev_category};
                    push @{$out->{$prev_category}}, $upperedToken;
                    next TOKEN;
                }
                $token_category = $upperedToken;
                last;
            }
            case "USER" {
                if ($prev_category eq "CREATE" or $prev_category eq "RENAME" or $prev_category eq "DROP") {
                    $token_category = $upperedToken;
                }
                last;
            }
            case "VIEW" {
                if ($prev_category eq "CREATE" or $prev_category eq "ALTER" or $prev_category eq "DROP") {
                    $token_category = $upperedToken;
                }
                last;
            }
            # These tokens get their own section, but have no subclauses.
            # These tokens identify the statement but have no specific subclauses of their own.
            case "DELETE" {}
            case "ALTER" {}
            case "INSERT" {}
            case "REPLACE" {}
            case "TRUNCATE" {}
            case "CREATE" {}
            case "TRUNCATE" {}
            case "OPTIMIZE" {}
            case "GRANT" {}
            case "REVOKE" {}
            case "SHOW" {}
            case "HANDLER" {}
            case "LOAD" {}
            case "ROLLBACK" {}
            case "SAVEPOINT" {}
            case "UNLOCK" {}
            case "INSTALL" {}
            case "UNINSTALL" {}
            case "ANALZYE" {}
            case "BACKUP" {}
            case "CHECK" {}
            case "CHECKSUM" {}
            case "REPAIR" {}
            case "RESTORE" {}
            case "DESCRIBE" {}
            case "EXPLAIN" {}
            case "USE" {}
            case "HELP" {
                $token_category = $upperedToken;
                $out->{$upperedToken} = [] unless exists $out->{$upperedToken};
                $out->{$upperedToken}[0] = $upperedToken;
                next TOKEN;
            }
            case "CACHE" {
                if ($prev_category eq "" or $prev_category eq "RESET" or $prev_category eq "FLUSH" or $prev_category eq "LOAD") {
                    $token_category = $upperedToken;
                    next TOKEN;
                }
                last;
            }
            case "LOCK" {
                if ($token_category eq "") {
                    $token_category = $upperedToken;
                    $out->{$upperedToken} = [] unless exists $out->{$upperedToken};
                    $out->{$upperedToken}[0] = $upperedToken;
                } else {
                    $trimedToken = "LOCK IN SHARE MODE";
                    $skip_next = 1;
                    $out->{"OPTIONS"} = [] unless exists $out->{"OPTIONS"};
                    push @{$out->{"OPTIONS"}}, $trimedToken;
                }
                next TOKEN;
                last;
            }
            case "USING" {
                if ($token_category eq "EXECUTE") {
                    $token_category = $upperedToken;
                    next TOKEN;
                }
                if ($token_category eq "FROM" and exists $out->{"DELETE"}) {
                    $token_category = $upperedToken;
                    next TOKEN;
                }
                last;
            }
            case "DROP" {
                if ($token_category ne "ALTER") {
                    $token_category = $upperedToken;
                    $out->{$upperedToken} = [] unless exists $out->{$upperedToken};
                    $out->{$upperedToken}[0] = $upperedToken;
                    next TOKEN;
                }
                last;
            }
            case "FOR" {
                $skip_next = 1;
                $out->{"OPTIONS"} = [] unless exists $out->{"OPTIONS"};
                push @{$out->{"OPTIONS"}}, "FOR UPDATE";
                next TOKEN;
                last;
            }
            case "UPDATE" {
                if ($token_category eq "") {
                    $token_category = $upperedToken;
                    next TOKEN;
                }
                if ($token_category eq "DUPLICATE") {
                    next TOKEN;
                }
                last;
            }
            case "START" {
                $trimedToken = "BEGIN";
                $out->{$upperedToken} = [] unless exists $out->{$upperedToken};
                $out->{$upperedToken}[0] = $upperedToken;
                $skip_next = 1;
                last;
            }
            case "BY" {}
            case "ALL" {}
            case "SHARE" {}
            case "MODE" {}
            case "TO" {}
            case ";" {
                next TOKEN;
                last;
            }
            case "KEY" {
                if ($token_category eq "DUPLICATE") {
                    next TOKEN;
                }
                last;
            }
            case "DISTINCTROW" {
                $trimedToken = "DISTINCT";
            }
            case "DISTINCT" {}
            case "HIGH_PRIORITY" {}
            case "LOW_PRIORITY" {}
            case "DELAYED" {}
            case "IGNORE" {}
            case "FORCE" {}
            case "STRAIGHT_JOIN" {}
            case "SQL_SMALL_RESULT" {}
            case "SQL_BIG_RESULT" {}
            case "QUICK" {}
            case "SQL_BUFFER_RESULT" {}
            case "SQL_CACHE" {}
            case "SQL_NO_CACHE" {}
            case "SQL_CALC_FOUND_ROWS" {
                $out->{"OPTIONS"} = [] unless exists $out->{"OPTIONS"};
                push @{$out->{"OPTIONS"}}, $upperedToken;
                next TOKEN;
                last;
            }
            case "WITH" {
                if ($token_category eq "GROUP") {
                    $skip_next = 1;
                    $out->{"OPTIONS"} = [] unless exists $out->{"OPTIONS"};
                    push @{$out->{"OPTIONS"}}, "WITH ROLLUP";
                    next TOKEN;
                }
                last;
            }
            case "AS" {
                last;
            }
            case "" {}
            case "," {}
            case ";" {
                last;
            }
            else {
                last;
            }
        }
        if($token_category ne "" and $prev_category eq $token_category){
            $out->{$token_category} = [] unless exists $out->{$token_category};
            push @{$out->{$token_category}}, $token;
        }
        $prev_category = $token_category;
    }
    return $self->processSQLParts($out);
}

sub processSQLParts {
    my $self = shift;
    my $out = shift;
    unless (defined $out) {
        return 0;
    }
    if (exists $out->{'SELECT'}) {
        $out->{'SELECT'} = $self->process_select($out->{'SELECT'});
    }
    if (exists $out->{'FROM'}) {
        $out->{'FROM'} = $self->process_from($out->{'FROM'});
    }
    if (exists $out->{'USING'}) {
        $out->{'USING'} = $self->process_from($out->{'USING'});
    }
    if (exists $out->{'UPDATE'}) {
        $out->{'UPDATE'} = $self->process_from($out->{'UPDATE'});
    }
    if (exists $out->{'GROUP'}) {
        # set empty array if we have partial SQL statement 
        $out->{'GROUP'} = $self->process_group($out->{'GROUP'}, exists $out->{'SELECT'} ? $out->{'SELECT'} : {});
    }
    if (exists $out->{'ORDER'}) {
        # set empty array if we have partial SQL statement
        $out->{'ORDER'} = $self->process_order($out->{'ORDER'}, exists $out->{'SELECT'} ? $out->{'SELECT'} : {});
    }
    if (exists $out->{'LIMIT'}) {
        $out->{'LIMIT'} = $self->process_limit($out->{'LIMIT'});
    }
    if (exists $out->{'WHERE'}) {
        $out->{'WHERE'} = $self->process_expr_list($out->{'WHERE'});
    }
    if (exists $out->{'HAVING'}) {
        $out->{'HAVING'} = $self->process_expr_list($out->{'HAVING'});
    }
    if (exists $out->{'SET'}) {
        $out->{'SET'} = $self->process_set_list($out->{'SET'});
    }
    if (exists $out->{'DUPLICATE'}) {
        $out->{'ON DUPLICATE KEY UPDATE'} = $self->process_set_list($out->{'DUPLICATE'});
        delete $out->{'DUPLICATE'};
    }
    if (exists $out->{'INSERT'}) {
        $out = $self->process_insert($out);
    }
    if (exists $out->{'REPLACE'}) {
        $out = $self->process_insert($out, 'REPLACE');
    }
    if (exists $out->{'DELETE'}) {
        $out = $self->process_delete($out);
    }
    if (exists $out->{'VALUES'}) {
        $out = $self->process_values($out);
    }
    if (exists $out->{'INTO'}) {
        $out = $self->process_into($out);
    }
    return $out;
}

sub maxNumericKey {
    my $queries = shift;
    my $maxKey = 0;
    foreach my $key (sort keys %$queries){
        if($key =~ /^\d+$/){
            $maxKey = int($key) > $maxKey ? int($key) : $maxKey;
        }
    }
    return $maxKey;
}
sub trim {
    my $str = shift;
    $str =~ s/^[\s\n\r\t\b]+|[\s\n\r\t\b]+$//g;
    return $str;
}
sub toUpperCase {
    my $str = shift;
    $str =~ tr/[a-z]/[A-Z]/;
    return $str;
}

sub getColumn {
    my $self = shift;
    my $base_expr = shift;
    my $col = $self->process_expr_list($self->{tokenizer}->split($base_expr));
    return {
        expr_type => "expression",
        base_expr => &trim($base_expr),
        sub_tree => $col,
    };
}

sub process_set_list {
    my $self = shift;
    my $tokens = shift || [];

    my $expr = {};
    my $base_expr = "";
    
}
=head1 AUTHOR

muddydixon, C<< <muddydixon at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-queryparser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-QueryParser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::QueryParser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-QueryParser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SQL-QueryParser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SQL-QueryParser>

=item * Search CPAN

L<http://search.cpan.org/dist/SQL-QueryParser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 muddydixon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SQL::QueryParser
