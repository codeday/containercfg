module.exports = (vars) => {
  return Object.keys(vars.tasks)
    .map((key) => ({ name: key, ...vars.tasks[key] }))
    .filter((task) => task.volumes && task.volumes.host)
    .map((task) => (task.volumes && task.volumes.host && task.volumes.host.map((vol) => ({
      Name: `${task.name}-${vol.volume}`,
      Type: 'host',
      Source: vol.volume,
      ReadOnly: vol.read_only != null ? vol.read_only : false,
    })) || [] ))
    .reduce((a, b) => [...a, ...b], [])
    .reduce((a, b) => { a[b.Name] = b; return a }, {});
}
