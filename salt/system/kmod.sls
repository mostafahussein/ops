
{% if salt['file.search']("/proc/bus/pci/devices", "103c323b") %}
# Hewlett-Packard Company Smart Array Gen8 Controllers
kmod.sg:
  kmod.present:
    - name: sg
{% endif %}
