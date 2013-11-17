#! /usr/bin/perl -w

open(FOO, "ospfsmod.c") || die "Did you delete ospfsmod.c?";
$lines = 0;
$lines++ while defined($_ = <FOO>);
close FOO;

@tests = (
    # test reading
    # 1
    [ 'diff base/hello.txt test/hello.txt >/dev/null 2>&1 && echo $?',
      "0"
    ],

    # 2
    [ 'cmp base/pokercats.gif test/pokercats.gif >/dev/null 2>&1 && echo $?',
      "0"
    ],

    # 3     
    [ 'ls -l test/pokercats.gif | awk "{ print \$5 }"',
      "91308"
    ],

    # 4 Read the first byte of the file
    [ 'head -c 1 test/hello.txt',
      "H"
    ],

    # 5 Read the first block of the file
    [ 'head -c 1024 test/longfile.txt',
      "0123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899100101102103104105106107108109110111112113114115116117118119120121122123124125126127128129130131132133134135136137138139140141142143144145146147148149150151152153154155156157158159160161162163164165166167168169170171172173174175176177178179180181182183184185186187188189190191192193194195196197198199200201202203204205206207208209210211212213214215216217218219220221222223224225226227228229230231232233234235236237238239240241242243244245246247248249250251252253254255256257258259260261262263264265266267268269270271272273274275276277278279280281282283284285286287288289290291292293294295296297298299300301302303304305306307308309310311312313314315316317318319320321322323324325326327328329330331332333334335336337338339340341342343344345346347348349350351352353354355356357358359360361362363364365366367368369370371372373374375376377"
    ],

    # 6 Read half of the first block of the file
    [ 'head -c 512 test/longfile.txt',
      "01234567891011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859606162636465666768697071727374757677787980818283848586878889909192939495969798991001011021031041051061071081091101111121131141151161171181191201211221231241251261271281291301311321331341351361371381391401411421431441451461471481491501511521531541551561571581591601611621631641651661671681691701711721731741751761771781791801811821831841851861871881891901911921931941951961971981992002012022032042052062"
     ],

     # Read tests that still need to be implemented
     # 7 Read starting part way into the first block and into the next block
     # 8 Read more than one block
     # 9 Try to read past the end of a file
     # 10 Try to read from an invalid buffer pointer


    # test writing
    # 7 We use dd to write because it doesn't initially truncate, and it can
    # be told to seek forward to a particular point in the disk.
    [ "echo Bybye | dd bs=1 count=5 of=test/hello.txt conv=notrunc >/dev/null 2>&1 ; cat test/hello.txt",
      "Bybye, world!"
    ],
    # 8 
    [ "echo Hello | dd bs=1 count=5 of=test/hello.txt conv=notrunc >/dev/null 2>&1 ; cat test/hello.txt",
      "Hello, world!"
    ],
    # 9 
    [ "echo gi | dd bs=1 count=2 seek=7 of=test/hello.txt conv=notrunc >/dev/null 2>&1 ; cat test/hello.txt",
      "Hello, girld!"
    ],
    # 10 
    [ "echo worlds galore | dd bs=1 count=13 seek=7 of=test/hello.txt conv=notrunc >/dev/null 2>&1 ; cat test/hello.txt",
      "Hello, worlds galore"
    ],
    # 11 
    [ "echo 'Hello, world!' > test/hello.txt ; cat test/hello.txt",
      "Hello, world!"
    ],
    
    # 12 create a file
    [ 'touch test/file1 && echo $?',
      "0"
    ],

    # 13 read directory
    [ 'touch test/dir-contents.txt ; ls test | tee test/dir-contents.txt | grep file1',
      'file1'
    ],

    # 14 write files, remove them, then read dir again
    [ 'ls test | dd bs=1 of=test/dir-contents.txt >/dev/null 2>&1; ' .
      ' touch test/foo test/bar test/baz && '.
      ' rm    test/foo test/bar test/baz && '.
      'diff <( ls test ) test/dir-contents.txt',
      ''
    ],

    # 15 remove the last file
    [ 'rm -f test/dir-contents.txt && ls test | grep dir-contents.txt',
      ''
    ],


    # 16 write to a file
    [ 'echo hello > test/file1 && cat test/file1',
      'hello'
    ],
    
    # 17 append to a file
    [ 'echo hello > test/file1 ; echo goodbye >> test/file1 && cat test/file1',
      'hello goodbye'
    ],

    # 18 delete a file
    [ 'rm -f test/file1 && ls test | grep file1',
      ''
    ],

    # 19 make a larger file for indirect blocks
    [ 'yes | head -n 5632 > test/yes.txt && ls -l test/yes.txt | awk \'{ print $5 }\'',
      '11264'
    ],
   
    # 20 truncate the large file
    [ 'echo truncernated11 > test/yes.txt | ls -l test/yes.txt | awk \'{ print $5 }\' ; rm test/yes.txt',
      '15'
    ],

    # Test Conditional Symlinks

    # 21 Conditional Symlink Test
    [ 'cd test; ln -s root?root:notroot amiroot;
       cat amiroot',
       'root'
    ],

    # 22 Not root Test
    [ 'cd test; su user -c "cat amiroot"; rm amiroot',
      'not root'
    ],


    # Test hardlinks
    # 21 Create a hard link
    #[ 'ln test/link_test test/hard_link; cat test/hard_link',
    #  'hello'
    #],

    # 22 Remove the original file
    #[ 'rm test/link_test; cat test/hard_link',
    #  'hello'
    #],

    # Test symlinks
    
    # 23 Create a symlink
    #[ 'ln -s test/hard_link test/symlink; cat test/symlink',
    #'hello'
      #],

    # 24 Remove original link for the symlink
    #[ 'rm test/hard_link; cat test/symlink',
    #  ''
    #],

);

my($ntest) = 0;
my(@wanttests);

foreach $i (@ARGV) {
    $wanttests[$i] = 1 if (int($i) == $i && $i > 0 && $i <= @tests);
}

my($sh) = "bash";
my($tempfile) = "lab3test.txt";
my($ntestfailed) = 0;
my($ntestdone) = 0;

foreach $test (@tests) {
    $ntest++;
    next if (@wanttests && !$wanttests[$ntest]);
    $ntestdone++;
    print STDOUT "Running test $ntest\n";
    my($in, $want) = @$test;
    open(F, ">$tempfile") || die;
    print F $in, "\n";
    print STDERR "  ", $in, "\n";
    close(F);
    $result = `$sh < $tempfile 2>&1`;
    $result =~ s|\[\d+\]||g;
    $result =~ s|^\s+||g;
    $result =~ s|\s+| |g;
    $result =~ s|\s+$||;

    next if $result eq $want;
    next if $want eq 'Syntax error [NULL]' && $result eq '[NULL]';
    next if $result eq $want;
    print STDERR "Test $ntest FAILED!\n  input was \"$in\"\n  expected output like \"$want\"\n  got \"$result\"\n";
    $ntestfailed += 1;
}

unlink($tempfile);
my($ntestpassed) = $ntestdone - $ntestfailed;
print "$ntestpassed of $ntestdone tests passed\n";
exit(0);
