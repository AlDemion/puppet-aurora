# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class aurora::scheduler {
  $aurora_ensure = $aurora::version? {
    undef    => absent,
    default => $aurora::version,
  }

  $packages = [
    'aurora-doc',
    'aurora-scheduler',
    'aurora-tools',
  ]

  package { $packages:
    ensure  => $aurora_ensure,
    require => Class['aurora::repo']
  }

  file { '/var/lib/aurora/scheduler':
    ensure  => 'directory',
    owner   => $aurora::owner,
    group   => $aurora::group,
    mode    => '0644',
    require => Package['aurora-scheduler'],
  }

  file { '/var/lib/aurora/scheduler/db':
    ensure  => 'directory',
    owner   => $aurora::owner,
    group   => $aurora::group,
    mode    => '0644',
    require => [
      Package['aurora-executor'],
      File['/var/lib/aurora/scheduler'],
    ]
  }

  file { '/etc/default/aurora-scheduler':
    ensure  => present,
    content => template('mesos/aurora-scheduler.erb'),
    owner   => $aurora::owner,
    group   => $aurora::group,
    mode    => '0644',
    require => Package['aurora-scheduler'],
  }

  if $init_mesos_log {
    exec { 'init-mesos-log':
      command => '/usr/bin/mesos-log initialize --path=/var/lib/aurora/scheduler/db',
      unless  => 'test -f /var/lib/aurora/scheduler/db/CURRENT',
      notify  => Service['aurora-scheduler'],
    }
  }
}
