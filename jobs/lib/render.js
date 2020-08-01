const getConstraints = require('./job/constraints');
const getType = require('./job/type');
const getUpdate = require('./job/update');
const getVolumes = require('./job/volumes');
const getTasks = require('./job/tasks');
const { strToNs } = require('./time');

module.exports = (vars) => {
  const Constraints = getConstraints(vars);
  const Type = getType(vars);
  const Update = getUpdate(vars);
  const Volumes = getVolumes(vars);
  const Tasks = getTasks(vars);

  return {
    ID: vars.job,
    Region: vars.region || 'global',
    Datacenters: vars.datacenters || [],
    Type,
    Constraints,
    Update,
    Periodic: Type === 'batch' && vars.placement.crontab && {
      Enabled: true,
      TimeZone: 'UTC',
      Spec: vars.placement.crontab,
      SpecType: 'cron',
    } || null,
    TaskGroups: [{
      Name: vars.job,
      Count: vars.deployment && vars.deployment.initial_count || 1,
      RestartPolicy: {
        Attempts: vars.deployment && vars.deployment.attempts || 2,
        Interval: strToNs('30m'),
        Delay: strToNs('15s'),
        Mode: 'fail',
      },
      Volumes,
      EphemeralDisk: {
        Sticky: false,
        SizeMb: (Tasks.length * 5 * 2 * 2) + 250, // Log storage + 250mb
        Migrate: false,
      },
      Tasks,
    }]
  }
}
