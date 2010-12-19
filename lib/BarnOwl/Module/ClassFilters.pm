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

my $filterdir = "$ENV{'HOME'}/.owl/classfilters";

sub list_classfilter_files
{
    return glob "$filterdir/*" or die "Error opening directory $filterdir: $!";
}

sub list_classfilters
{
    return map { $1 if /([^\/]+)$/ } list_classfilter_files();
}

sub filtername_to_filename
{
    my $filtername = shift;
    return "$filterdir/$filtername";
}

sub load_classfilters
{
    my $verbose = shift;

    my @filenames = list_classfilter_files();
    for my $filename (@filenames) {
        load_classfilter_from_file($verbose, $filename);
    }
}

sub load_classfilter
{
    my $verbose = shift;
    my $filtername = shift;

    my $filename = filtername_to_filename($filtername);
    load_classfilter_from_file($verbose, $filename);
}

sub get_classfilter
{
    my $filtername = shift;

    my @classfilters = list_classfilters();
    if (!grep(/^$filtername$/, @classfilters)) {
        BarnOwl::message("Error: No filter named '$filtername'.");
        return undef;
    }

    my $filename = filtername_to_filename($filtername);
    my $contents;
    { 
      local $/=undef;
      open FILE, $filename or die "Couldn't open file: $!";
      $contents = <FILE>;
      close FILE;
    }

    return $contents;
}

sub load_classfilter_from_file 
{
    my $verbose = shift;
    my $filename = shift;

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

sub classfilter_append
{
    my $verbose = shift;
    my $filtername = shift;
    my @filter = @_;

    my @classfilters = list_classfilters();
    if (!grep(/^$filtername$/, @classfilters)) {
        BarnOwl::message("Error: No filter named '$filtername'.");
        return 0;
    }

    my $filename = filtername_to_filename($filtername);
    open my $file, '>>', $filename or die "Error opening file $filename: $!";
    print {$file} "@filter\n";
    close $file;
    load_classfilter_from_file($verbose, $filename);
    return 1;
}

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

sub cmd_reload_classfilter {
    my $cmd = shift;
    my $arg1 = shift;
    my $arg2 = shift;
    if (defined $arg1) {
        if ($arg1 eq '-v') {
            if (defined $arg2) {
                load_classfilter(1, $arg2);
            } else {
                BarnOwl::message("Error: Must specify a filter to reload");
                return;
            }
        } else {
            load_classfilter(0, $arg1);
        }
    } else {
        BarnOwl::message("Error: Must specify a filter to reload");
        return;
    }
    BarnOwl::message("Filter loaded.");
}

BarnOwl::new_command('reload-classfilter' => \&cmd_reload_classfilter, {
    summary             => 'Reload a specified filter from file in ~/.owl/classfilters',
    usage               => 'reload-classfilter [-v] NAME',
    description         => 'Reload a specified filter from ~/.owl/classfilters.'
    . "\n-v (verbose), if provided, displays the filter created."
    });

sub cmd_list_classfilters {
    my $cmd = shift;
    BarnOwl::popless_text("Available classfilters:\n\n" . join("\n", list_classfilters()));
}

BarnOwl::new_command('list-classfilters' => \&cmd_list_classfilters, {
    summary             => 'list the available classfilters',
    usage               => 'list-classfilters',
    description         => 'List the available classfilters'
    });

sub cmd_show_classfilter {
    my $cmd = shift;
    my $filtername = shift;
    my $r = undef;
    if (defined $filtername) {
        $r = get_classfilter($filtername);
    } else {
        BarnOwl::message("Error: Must specify a filter name.");
        return;
    }
    BarnOwl::popless_text("Classfilter '$filtername':\n\n" . $r) if $r;
}

BarnOwl::new_command('show-classfilter' => \&cmd_show_classfilter, {
    summary             => 'show a specific classfilter',
    usage               => 'show-classfilter NAME',
    description         => 'Show the contents of a specific classfilter'
    });

sub cmd_classfilter_append {
    my $cmd = shift;
    my $arg1 = shift;
    my $arg2 = shift;
    my $r = 0;
    if (defined $arg1) {
        if ($arg1 eq '-v') {
            if (defined $arg2) {
                $r = classfilter_append(1, $arg2, @_);
            } else {
                BarnOwl::message("Error: Must specify a filter to append to");
                return;
            }
        } else {
            $r = classfilter_append(0, $arg1, $arg2, @_);
        }
    } else {
        BarnOwl::message("Error: Must specify a filter to append to");
        return;
    }
    BarnOwl::message("Filter loaded.") if $r;
}

BarnOwl::new_command('classfilter-append' => \&cmd_classfilter_append, {
    summary             => 'Append a line to the filter and file in ~/.owl/classfilters',
    usage               => 'classfilter-append [-v] NAME FILTER',
    description         => 'Append a line to the filter and file in ~/.owl/classfilters'
    . "\n-v (verbose), if provided, displays the filter created."
    });


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
