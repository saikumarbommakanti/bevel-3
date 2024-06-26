apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-{{ peer_name }}
  namespace: {{ peer_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  interval: 1m
  releaseName: {{ name }}-{{ peer_name }}
  chart:
    spec:
      interval: 1m
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
      chart: {{ charts_dir }}/fabric-peernode    
  values:
{% if network.upgrade is defined %}
    upgrade: {{ network.upgrade }}
{% endif %}
    metadata:
      namespace: {{ peer_ns }}
      images:
        couchdb:  {{ docker_url }}/{{ couchdb_image[network.version] }}
        peer:  {{ docker_url }}/{{ peer_image[network.version] }}
        alpineutils: {{ docker_url }}/{{ alpine_image }}

{% if network.env.annotations is defined %}
    annotations:  
      service:
{% for item in network.env.annotations.service %}
{% for key, value in item.items() %}
        - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
      pvc:
{% for item in network.env.annotations.pvc %}
{% for key, value in item.items() %}
        - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
      deployment:
{% for item in network.env.annotations.deployment %}
{% for key, value in item.items() %}
        - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
{% endif %}  
{% if network.env.labels is defined %}
    labels:
{% if network.env.labels.service is defined %}
      service:
{% for key in network.env.labels.service.keys() %}
        - {{ key }}: {{ network.env.labels.service[key] | quote }}
{% endfor %}
{% endif %}
{% if network.env.labels.pvc is defined %}
      pvc:
{% for key in network.env.labels.pvc.keys() %}
        - {{ key }}: {{ network.env.labels.pvc[key] | quote }}
{% endfor %}
{% endif %}
{% if network.env.labels.deployment is defined %}
      deployment:
{% for key in network.env.labels.deployment.keys() %}
        - {{ key }}: {{ network.env.labels.deployment[key] | quote }}
{% endfor %}
{% endif %}
{% endif %}

    peer:
      name: {{ peer_name }}
      gossippeeraddress: {{ peer.gossippeeraddress }}
{% if provider == 'none' %}
      gossipexternalendpoint: {{ peer_name }}.{{ peer_ns }}:7051
{% else %}
      gossipexternalendpoint: {{ peer.peerAddress }}
{% endif %}
      localmspid: {{ name }}MSP
      loglevel: info
      tlsstatus: true
      builder: hyperledger/fabric-ccenv:{{ network.version }}
      couchdb:
        username: {{ name }}-user
{% if peer.configpath is defined %}
      configpath: conf/{{ peer_name }}_{{ name }}_core.yaml
      core: |-
{{ core_file | indent(width=8, first=True) }}
{% endif %}

    storage:
      peer:
        storageclassname: {{ sc_name }}
        storagesize: 512Mi
      couchdb:
        storageclassname: {{ sc_name }}
        storagesize: 1Gi

    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ item.k8s.cluster_id | default('')}}{{ network.env.type }}{{ item.name | lower }}
      secretprefix: {{ vault.secret_path | default('secretsv2') }}/data/{{ item.name | lower }}/peerOrganizations/{{ namespace }}/peers/{{ peer_name }}.{{ namespace }}
      serviceaccountname: vault-auth
      type: {{ vault.type | default("hashicorp") }}
{% if network.docker.username is defined and network.docker.password is defined %}
      imagesecretname: regcred
{% else %}
      imagesecretname: ""
{% endif %}
      secretcouchdbpass: {{ vault.secret_path | default('secretsv2') }}/data/{{ item.name | lower }}/credentials/{{ namespace }}/couchdb/{{ name }}?user

    service:
      servicetype: ClusterIP
      ports:
        grpc:
          clusteripport: {{ peer.grpc.port }}
{% if peer.grpc.nodePort is defined %}
          nodeport: {{ peer.grpc.nodePort }}
{% endif %}
        events:
          clusteripport: {{ peer.events.port }}
{% if peer.events.nodePort is defined %}
          nodeport: {{ peer.events.nodePort }}
{% endif %}
        couchdb:
          clusteripport: {{ peer.couchdb.port }}
{% if peer.couchdb.nodePort is defined %}
          nodeport: {{ peer.couchdb.nodePort }}
{% endif %}
        metrics: 
          enabled: {{ peer.metrics.enabled | default(false) }}
          clusteripport: {{ peer.metrics.port | default(9443) }}     
    proxy:
      provider: "{{ network.env.proxy }}"
      external_url_suffix: {{ item.external_url_suffix }}

    config:
      pod:
        resources:
          limits:
            memory: 512M
            cpu: 1
          requests:
            memory: 512M
            cpu: 0.25
