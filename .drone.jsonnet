local apt_get_quiet = 'apt-get -o=Dpkg::Use-Pty=0 -q';


local builder_image(distro, arch) = 'registry.oxen.rocks/lokinet-ci-' + std.strReplace(distro, '/', '-') + '-builder/' + (
  if arch == 'arm64' then 'arm64v8' else if arch == 'armhf' then 'arm32v7' else arch
);

local scripts_for(distros, arches, scripts, add_source_repo=[], jobs=0) = [
  {
    kind: 'pipeline',
    type: 'docker',
    platform: { arch: if std.startsWith(arch, 'arm') then 'arm64' else 'amd64' },
    name: std.asciiUpper(std.substr(distro, 0, 1)) + std.substr(distro, 1, 1000) + '/' + arch,
    steps: [{
      name: script,
      image: builder_image(distro, arch),
      pull: 'always',
      environment: { JOBS: if jobs > 0 then jobs else if std.startsWith(arch, 'arm') then 4 else 6 },
      commands: [
        './setup-apt.sh ' + std.strReplace(distro, '/', ' ') + ' ' + std.join(' ', add_source_repo),
        './build-' + script + '.sh ' + std.split(distro, '/')[1] + ' ' + arch,
      ],
    } for script in scripts] + [{
      name: 'Upload',
      image: builder_image('debian/bookworm', arch),
      pull: 'always',
      environment: { SSH_KEY: { from_secret: 'SSH_KEY' } },
      commands: [
        './ci-upload.sh ' + distro + ' ' + arch,
      ],
    }],
  }
  for distro in distros
  for arch in arches
  if !(std.startsWith(distro, 'ubuntu') && arch == 'i386')
];


scripts_for([
              'debian/sid',
              'debian/trixie',
              'debian/bookworm',
              'ubuntu/mantic',
              'ubuntu/lunar',
              'ubuntu/jammy',
            ],
            ['amd64', 'arm64', 'i386', 'armhf'],
            ['ngtcp2'],
            ['experimental']) +
scripts_for([
              'debian/bullseye',
            ],
            ['amd64'],
            ['gnutls', 'ngtcp2'],
            ['experimental', 'sid']) +
scripts_for([
              'ubuntu/focal',
            ],
            ['amd64'],
            ['nettle', 'gnutls', 'ngtcp2'],
            ['experimental', 'sid']) +
scripts_for([
              'debian/buster',
              'ubuntu/bionic',
            ],
            ['amd64'],
            ['nettle', 'gnutls', 'ngtcp2', 'libsodium'],
            ['experimental', 'sid']) +
[]
