: <<'END_COMMENT'
This is a heredoc (<<) redirected to a NOP command (:).
The single quotes around END_COMMENT are important,
because it disables variable resolving and command resolving
within these lines.  Without the single-quotes around END_COMMENT,
the following two $() `` commands would get executed:
$(gibberish command)
`rm -fr mydir`
comment1
comment2 
comment3
END_COMMENT

: '
This is a
very neat comment
in bash
'

# Another comment