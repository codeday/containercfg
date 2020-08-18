const getPlacementConstraints = (placement) => {
  const constraints = [];

  if (placement && placement.type === 'unique') constraints.push({
    Operand: 'distinct_hosts',
  });

  if (placement && placement.os_type) constraints.push({
    LTarget: '${attr.kernel.name}',
    Operand: '==',
    RTarget: placement.os_type,
  });

  if (placement && placement.os) constraints.push({
    LTarget: '${attr.os.name}',
    Operand: '==',
    RTarget: placement.os,
  });

  if (placement && placement.os_version) constraints.push({
    LTarget: '${attr.os.version}',
    Operand: '>=',
    RTarget: placement.os_version,
  });

  if (placement && placement.os) constraints.push({
    LTarget: '${meta.host}',
    Operand: '==',
    RTarget: placement.host_dc,
  });

  if (!placement || (placement && placement.speed !== null)) constraints.push({
    LTarget: '${meta.speed}',
    Operand: '==',
    RTarget: placement && placement.speed || 'gbps',
  });


  return constraints;
}

module.exports = (vars) => [ ...getPlacementConstraints(vars.placement), ...(vars.constraints || []) ];
