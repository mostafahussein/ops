service.redmine:
  service.running:
    - name: redmine
    - enable: True
    - sig: "/usr/bin/ruby /var/lib/redmine/script/rails"
