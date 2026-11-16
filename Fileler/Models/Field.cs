using System;
using System.Collections.Generic;

namespace Fileler.Models;

public partial class Field
{
    public int Id { get; set; }

    public int FacilityId { get; set; }

    public string Name { get; set; } = null!;

    public virtual Facility Facility { get; set; } = null!;

    public virtual ICollection<TimeSlot> TimeSlots { get; set; } = new List<TimeSlot>();
}
