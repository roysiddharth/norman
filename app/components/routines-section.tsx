"use client";

import { useEffect, useState } from "react";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type Routine = {
  name: string;
  schedule: string;
  enabled: boolean;
  fallback_type: string;
};

export function RoutinesSection() {
  const [routines, setRoutines] = useState<Routine[]>([]);
  const [loading, setLoading] = useState(true);

  function fetchRoutines() {
    fetch("/api/routines")
      .then((r) => r.json())
      .then((data) => {
        setRoutines(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }

  useEffect(() => {
    fetchRoutines();
    const id = setInterval(fetchRoutines, 15_000);
    return () => clearInterval(id);
  }, []);

  if (loading) {
    return <p className="text-muted-foreground text-sm">Loading…</p>;
  }

  if (routines.length === 0) {
    return <p className="text-muted-foreground text-sm">No routines configured.</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Name</TableHead>
          <TableHead>Schedule</TableHead>
          <TableHead>Enabled</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {routines.map((routine) => (
          <TableRow key={routine.name}>
            <TableCell className="font-medium">{routine.name}</TableCell>
            <TableCell className="text-muted-foreground">{routine.schedule || "—"}</TableCell>
            <TableCell>
              <Badge variant={routine.enabled ? "default" : "secondary"}>
                {routine.enabled ? "enabled" : "disabled"}
              </Badge>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
