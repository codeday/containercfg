const { getPortMap, getNetworkPorts } = require('./ports');
const { getTemplates, getEnvTemplate } = require('./vault');
const getServices = require('./service');
const {
  getShareMountsFor,
  getRawMountsFor,
  getTmpfsMountsFor,
  getVolumeMountsFor,
  getArtifactsFor,
} = require('./volumes');

module.exports = (vars) => {
  return Object.keys(vars.tasks)
    .map((key) => ({ name: key, ...vars.tasks[key] }))
    .map((task) => {
      const dockerMount = task.allow_docker_sock ? ["/var/run/docker.sock:/var/run/docker.sock"] : [];
      return {
        Name: task.name,
        Driver: 'docker',
        Config: {
          dns_servers: ['169.254.1.1'],
          image: `${task.image}:${task.version || 'latest'}`,
          args: task.args || [],
          port_map: getPortMap(task),
          cap_add: task.capacities || [],
          command: task.command,
          userns_mode: task.allow_docker_sock ? 'host' : undefined,
          volumes: [
            ...getShareMountsFor(task),
            ...getRawMountsFor(task),
            ...dockerMount,
          ],
          mounts: getTmpfsMountsFor(task),
          ...(task.resources.memory_limit ? { memory_hard_limit: task.resources.memory_limit } : {}),
        },
        VolumeMounts: getVolumeMountsFor(task),
        Artifacts: getArtifactsFor(task),
        Resources: {
          CPU: task.resources && task.resources.cpu || 100,
          MemoryMB: task.resources && task.resources.memory || 256,
          Mode: task.host_network ? 'host' : '',
          Networks: [{
            DynamicPorts: getNetworkPorts(task).filter((port) => port.Value === 0),
            ReservedPorts: getNetworkPorts(task).filter((port) => port.Value !== 0),
          }],
        },
        LogConfig: {
          MaxFiles: 2,
          MaxFileSizeMB: 5,
        },
        EphemeralDisk: {
          Sticky: false,
          SizeMB: task.resources && task.resources.disk || 100,
          Migrate: false,
        },
        Env: task.env && Object.keys(task.env).map((k) => ({k, v: `${task.env[k]}`})).reduce((a,b) => { a[b.k] = b.v; return a; }, {}) || null,
        Vault: task.vault && task.vault.policies && {
          Policies: task.vault && task.vault.policies,
          Env: true,
          ChangeMode: 'signal',
          ChangeSignal: 'SIGHUP',
        },
        Templates: [
          ...getTemplates(task),
          ...getEnvTemplate(task),
        ],
        Services: getServices(task, vars.job),
      }
    });
}
