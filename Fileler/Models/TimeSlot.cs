using System;
using System.Collections.Generic;

namespace Fileler.Models;

public partial class TimeSlot
{
    public int Id { get; set; }

    public int FieldId { get; set; }

    public TimeOnly StartTime { get; set; }

    public TimeOnly EndTime { get; set; }

    public decimal Price { get; set; }

    public virtual Field Field { get; set; } = null!;

    public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
