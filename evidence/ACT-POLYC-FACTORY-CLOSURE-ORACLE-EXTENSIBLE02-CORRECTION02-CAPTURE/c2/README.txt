ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE02-CORRECTION02-CAPTURE / c2 / README.txt

This directory preserves the whitespace-clean content of 4 closed
CORRECTION01 evidence files as captured at the C0 boundary of
CORRECTION03 (commit 87aec89).

CORRECTION02 physically modified these 4 files at its C2 IMPL/FREEZE
commit (a865dc8). The reviewer's P0-G2 disposition is that this
modification violated F14 closed-evidence immutability. CORRECTION03
restores those 4 files to their exact historical b9a43f8 blobs
(F14 restoration). This directory preserves the
CORRECTION02-produced content as additive evidence so that the
information is not lost.

File mapping (capture -> source at C0 boundary 87aec89):

  correction02-cleaned-c2-p02-n01-n05-regression.txt
    <- evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
       CORRECTION01/c2/c2-p02-n01-n05-regression.txt
       at 87aec89
    (sha256 at 87aec89: 73ed882d24b78440be1d33deda79324c6761f3a356e7cde3b85bc6820de0cdcc
     sha256 at b9a43f8: 5553b2ab7765ee016afdfbf7cbcd6bd20b9504558e9754af49d33fd25b479766)

  correction02-cleaned-c3-act-body-unchanged.txt
    <- evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
       CORRECTION01/c3/c3-act-body-unchanged.txt
       at 87aec89
    (sha256 at 87aec89: ac5982f5460990a018ebf3cea89bca455c9dcae12855bec5b5349e5af5b8df8f
     sha256 at b9a43f8: 42c26008ee6796459093b2052b119258afbe66b9f3a36e6cd68e75cc4d4be23a)

  correction02-cleaned-c3-checker-unchanged.txt
    <- evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
       CORRECTION01/c3/c3-checker-unchanged.txt
       at 87aec89
    (sha256 at 87aec89: 58557f6406618bcef9322790d42600e1d9920eb97c3960e392f8b3ab706ba0a3
     sha256 at b9a43f8: 44ad8de0c5d2793224755c5b3576ce94a63c1db812fa3aa31c885715bebd9cdd)

  correction02-cleaned-c3-manifest-unchanged.txt
    <- evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
       CORRECTION01/c3/c3-manifest-unchanged.txt
       at 87aec89
    (sha256 at 87aec89: 6ffa0c96f5c94f477e561f2e8b9cb2cc2a131b2f933011f5a95f4117d1e5a7b6
     sha256 at b9a43f8: 0bb36968dcde5996b02b3c1a3ffab8d2d5d99496e6bc107aa54c45e03a239165)

After this capture is committed, the 4 source files will be
restored to their b9a43f8 historical blobs via subsequent commits.
