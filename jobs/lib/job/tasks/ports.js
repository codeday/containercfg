module.exports.getPortMap = (task) => {
  if (!task.ports) return [];
  return [Object.keys(task.ports)
    .map((portName) => ({ name: portName, ...task.ports[portName] }))
    .reduce((a, b) => { a[b.name] = b.inner; return a; }, {})];
}

module.exports.getNetworkPorts = (task) => {
  if (!task.ports) return [];
  return Object.keys(task.ports)
    .map((portName) => ({ name: portName, ...task.ports[portName] }))
    .map((port) => ({
      Label: port.name,
      Value: port.outer || 0,
      To: 0,
    }));
}
