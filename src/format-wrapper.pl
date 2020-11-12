use strict;
use warnings;
use utf8;

my $SLESS_HOME = $ENV{"SLESS_HOME"};

my $format = "";
my $verbose_flag = "";
my $color_flag = "";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--json") {
        $format = "json";
    } elsif ($a eq "--tsv") {
        $format = "tsv";
    } elsif ($a eq "-v") {
        $verbose_flag = 1;
    } elsif ($a eq "--color") {
        $color_flag = 1;
    } else {
        die "Unknown argument: $a\n";
    }
}

my $head_size = 100 * 4096;

my $head_buf = "";

my $left_size = $head_size;
my $gzip_flag = '';
my $xz_flag = '';
while () {
    if ($left_size <= 0) {
        last;
    }
    my $head_buf2;
    my $l = sysread(STDIN, $head_buf2, $left_size);
    if ($l == 0) {
        last;
    }
    $head_buf .= $head_buf2;
    if ($left_size >= $head_size - 2) {
        if ($head_buf =~ /\A\x1F\x8B/) {
            $gzip_flag = 1;
            last;
        }
    }
    if ($left_size >= $head_size - 6) {
        if ($head_buf =~ /\A\xFD\x37\x7A\x58\x5A\x00/) {
            $xz_flag = 1;
            last;
        }
    }
    $left_size -= $l;
}

if ($gzip_flag || $xz_flag) {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my $READER2;
    my $WRITER2;
    pipe($READER2, $WRITER2);

    my $pid2 = fork;
    die $! if (!defined $pid2);
    if (!$pid2) {
        # gunzip or xz のプロセスをexecする
        close $READER2;
        open(STDOUT, '>&=', fileno($WRITER2));
        if ($gzip_flag) {
            exec("gunzip", "-c");
        } elsif ($xz_flag) {
            exec("xz", "-c", "-d");
        } else {
            die;
        }
    }
    close $WRITER2;
    open(STDIN, '<&=', fileno($READER2));

    my @options = ();
    if ($format eq "json") {
        push(@options, "--json");
    }
    if ($verbose_flag) {
        push(@options, "-v");
    }
    if ($color_flag) {
        push(@options, "--color");
    }

    if ($verbose_flag) {
        if ($gzip_flag) {
            print STDERR "format=gzip\n";
        } elsif ($xz_flag) {
            print STDERR "format=xz\n";
        }
    }
    exec("perl", "$SLESS_HOME/format-wrapper.pl", @options);
}

sub guess_format {
    my ($head_buf) = @_;
    my @lines = split(/\r?\n/, $head_buf);

    if (@lines >= 2 && $lines[0] =~ /\t/ && $lines[1] =~ /\t/) {
        return "tsv";
    }

    if ($lines[0] =~ /\A\{/) {
        if (@lines >= 2 && $lines[1] =~ /\A\{/) {
            return "jsonl";
        } else {
            return "json";
        }
    }

    # failed to guess format
    return "text";
}

if ($format eq '') {
    $format = guess_format($head_buf);
}

# フォーマットの推定結果を出力
if ($verbose_flag) {
    print STDERR "format=$format\n";
}

if ($format eq "json" || $format eq "jsonl") {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my @options = ();
    push(@options, ".");
    if ($color_flag) {
        push(@options, "-C");
    } else {
        push(@options, "-M");
    }
    if ($format eq "jsonl") {
        push(@options, "-c");
    }
    exec("jq", @options);
}

if ($format eq "tsv") {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my @options = ();
    if ($color_flag) {
        push(@options, "--color");
    }
    exec("perl", "$SLESS_HOME/table.pl", @options);
}

# 先読みした内容を出力
syswrite(STDOUT, $head_buf);

# 残りの入力をそのまま出力
exec("cat");

