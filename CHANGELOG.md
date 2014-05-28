[HEAD][]
--------

[v1.1.1][]
----------

- Fix Mellon::Store for empty keychain entries (c3d1da52)
- Fix mistaking error reading keychain from missing entry (782d2d82)
- Show stderr and exit status when `mellon edit` fails (fd2eecee)

[v1.1.0][]
----------

- `mellon list -k keychain` now lists all keys in given keychain (d34052c0)
- `mellon list` now lists all keys in all keychains (e9d67f10)
- Implemented Mellon::Keychain#keys (7ee9c3fe)
- Implemented equality checking for Mellon::Keychain (4368c73c)

[v1.0.0][]
----------

Initial release!

[HEAD]: https://github.com/elabs/mellon/compare/v1.1.1...HEAD
[v1.1.1]: https://github.com/elabs/mellon/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/elabs/mellon/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/elabs/mellon/compare/24b83977d...v1.0.0
