# zit

A toy implementation of [Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) in zig.

## Available CLI commands:

```
zit <command>
```

- `init`: Initialize the object store at `./zit/objects`.
- `hash-object <file-path>`: Write compressed blob of file at `<file-path>` to object storage.
- `cat-file <object-hash>`: Cat the content of the compressed blob with hash `<object-hash>` to stdout.
