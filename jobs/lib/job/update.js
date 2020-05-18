const getType = require('./type');
const { strToNs } = require('../time');

module.exports = (vars) => {
  let { deployment } = vars;
  if (getType(vars) !== 'service') return null;
  if (!deployment) deployment = {};

  const Canary = deployment.canaries == null ? 1 : deployment.canaries;

  return {
    MaxParallel: deployment.max_parallel || 1,
    HealthCheck: Object.values(vars.tasks)
      .filter((t) => t.ports && Object.values(t.ports).filter((p) => typeof p.check !== 'undefined').length > 0).length > 0
      ? 'checks' : 'task_states',
    HealthyDeadline: strToNs(deployment.healthy_deadline || '3m'),
    MinHealthyTime: strToNs(deployment.min_healthy_time || '10s'),
    ProgressDeadline: strToNs(deployment.progress_deadline || '10m'),
    Canary,
    AutoPromote: Canary > 0,
    AutoRevert: deployment.no_revert_on_failure == null ? true : deployment.no_revert_on_failure,
  }
}
