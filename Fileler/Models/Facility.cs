using System;
using System.Collections.Generic;

namespace Fileler.Models;

public partial class Facility
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string City { get; set; } = null!;

    public string? Address { get; set; }

    public virtual ICollection<Field> Fields { get; set; } = new List<Field>();
}
