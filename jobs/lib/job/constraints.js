const getPlacementConstraints = (placement) => {
  if (!placement) return [];
  const constraints = [];

  if (placement.type === 'unique') constraints.push({
    Operand: 'distinct_hosts',
  });

  if (placement.os_type) constraints.push({
    LTarget: '${attr.kernel.name}',
    Operand: '==',
    RTarget: placement.os_type,
  });

  if (placement.os) constraints.push({
    LTarget: '${attr.os.name}',
    Operand: '==',
    RTarget: placement.os,
  });

  if (placement.os_version) constraints.push({
    LTarget: '${attr.os.version}',
    Operand: '>=',
    RTarget: placement.os_version,
  });

  return constraints;
}

module.exports = (vars) => [ ...getPlacementConstraints(vars.placement), ...(vars.constraints || []) ];
