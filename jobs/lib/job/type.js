module.exports = (vars) => {
  if (!vars.placement || !vars.placement.type) return 'service';
  if (vars.placement.type === 'all') return 'system';
  if (vars.placement.type === 'batch') return 'batch';
  return 'service';
}
