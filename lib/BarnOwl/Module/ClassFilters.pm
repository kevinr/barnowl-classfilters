package BarnOwl::Module::ClassFilters;

use warnings;
use strict;

=head1 NAME

BarnOwl::Module::ClassFilters - Load BarnOwl filters from ~/.owl/classfilters

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Put this in ~/.owl/modules and run :reload-modules in your BarnOwl (or 
:reload-module ClassFilters).

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 load_classfilters

The business end of the module.

=cut

use BarnOwl;
use BarnOwl::Hooks;

$BarnOwl::Hooks::getQuickstart->add( sub { classfilters_quickstart(@_); } );

sub classfilters_quickstart {
    return <<'END_DESC';
@b[BarnOwl::Module::ClassFilters]:
Put files describing filters in ~/.owl/classfilters.

Filters are automatically loaded on startup or whenever the module is reloaded.

Adds the :reload-classfilters command.
END_DESC
}

sub load_classfilters
{
    my $verbose = shift;

    my $filterdir = "$ENV{'HOME'}/.owl/classfilters";
    my @filenames = glob "$filterdir/*" or die "Error opening directory $filterdir: $!";
    for my $filename (@filenames) {
        open my $file, '<', $filename or die "Error opening file $filename: $!";

        my @path_parts = split /\//, $filename;        # portability, what portability?
        my $filtername = pop @path_parts;

        my @filter_parts;
        my $lines = 0;
        while (<$file>) {
            if (/^\s*\(/) {
                push @filter_parts, 'or' if $lines++ > 0;
                chomp(my $filter_section = $_);
                push @filter_parts, $filter_section;
                next;
            }
            my @parts = split /,/;
            chomp(my $class = $parts[0]) if @parts > 0;
            my $has_class = $class ne '*';
            chomp(my $instance = $parts[1]) if @parts > 1;
            my $has_instance = defined $instance && $instance ne '*';
            chomp(my $recipient = $parts[2]) if @parts > 2;
            my $has_recipient = defined $recipient && $recipient ne '*';

            if ($has_class || $has_instance || $has_recipient) {
                push @filter_parts, 'or' if $lines++ > 0;
                push @filter_parts, '(';
                push @filter_parts, "class ^(un)?$class\$" if $has_class;
                push @filter_parts, "and" if $has_class && $has_instance;
                push @filter_parts, "instance ^(un)?$instance\$" if $has_instance;
                push @filter_parts, "and" if ($has_class || $has_instance) && $has_recipient;
                push @filter_parts, "recipient ^$recipient\$" if $has_recipient;
                push @filter_parts, ')';
            }
        }

        BarnOwl::admin_message("classfilters filter", "filter '$filtername': @filter_parts") if $verbose;
        BarnOwl::set_filter($filtername, "@filter_parts");
        close $file;
    }
}

sub cmd_reload_classfilters {
    my $cmd = shift;
    my $verbose = shift;
    if (defined $verbose && $verbose eq '-v') {
        load_classfilters(1);
    } else {
        load_classfilters(0);
    }
    BarnOwl::message("Filters loaded.");
}

BarnOwl::new_command('reload-classfilters' => \&cmd_reload_classfilters, {
    summary             => 'Reload filters from files in ~/.owl/classfilters',
    usage               => 'reload-classfilters [-v]',
    description         => 'Reload filters from ~/.owl/classfilters.'
    . "\n-v (verbose), if provided, lists the filters as they are created."
    });
    

sub startup_load_classfilters {
    my $is_reload = shift;

    load_classfilters(0);
}

eval {
    $BarnOwl::Hooks::startup->add("BarnOwl::Module::ClassFilters::startup_load_classfilters");
};
if($@) {
    $BarnOwl::Hooks::startup->add(\&startup_load_classfilters);
}


=head1 AUTHOR

Kevin Riggle, C<< <kevinr at free-dissociation.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<kevinr at free-dissociation.com>.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BarnOwl::Module::ClassFilters


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kevin Riggle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of BarnOwl::Module::ClassFilters
