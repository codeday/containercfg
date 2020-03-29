module.exports.getShareMountsFor = (task) => {
  return !(task.volumes && task.volumes.share)
    ? []
    : Object.values(task.volumes.share)
      .map((share) => `/fileshare/${share.fileshare}:${share.mountpoint}`)
}

module.exports.getRawMountsFor = (task) => {
  return !(task.volumes && task.volumes.raw)
    ? []
    : Object.values(task.volumes.raw)
      .map((raw) => `${raw.from}:${raw.mountpoint}`)
}

module.exports.getTmpfsMountsFor = (task) => {
  return !(task.volumes && task.volumes.tmpfs)
    ? []
    : Object.values(task.volumes.tmpfs)
      .map((tmpfs) => ({
        type: 'tmpfs',
        target: tmpfs,
        readonly: false,
      }));
}

module.exports.getVolumeMountsFor = (task) => {
  return !(task.volumes && task.volumes.host)
    ? []
    : Object.values(task.volumes.host)
      .map((host) => ({
        Volume: `${task.name}-${host.volume}`,
        Destination: host.mountpoint,
        ReadOnly: host.read_only != null ? host.read_only : false,
      }));
}

module.exports.getArtifactsFor = (task) => {
  return !(task.volumes && task.volumes.artifact)
    ? []
    : Object.values(task.volumes.artifact)
      .map((artifact) => ({
        GetterSource: artifact.source,
        GetterOptions: null,
        GetterMode: 'any',
        RelativeDest: artifact.destination,
      }));
}
