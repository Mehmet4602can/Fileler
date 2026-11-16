using System;
using System.Collections.Generic;

namespace Fileler.Models;

public partial class Reservation
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int TimeSlotId { get; set; }

    public DateOnly ReservationDate { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual TimeSlot TimeSlot { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
