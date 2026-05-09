"use client";

import { useEffect, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type QueueItem = {
  filename: string;
  description: string;
  type: string;
  status: string;
  added_at: string;
};

type StatusFilter = "all" | "pending" | "done";

function formatDate(iso: string) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

export function QueueSection() {
  const [items, setItems] = useState<QueueItem[]>([]);
  const [filter, setFilter] = useState<StatusFilter>("pending");
  const [loading, setLoading] = useState(true);

  function fetchQueue() {
    fetch("/api/queue")
      .then((r) => r.json())
      .then((data) => {
        setItems(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }

  useEffect(() => {
    fetchQueue();
    const id = setInterval(fetchQueue, 15_000);
    return () => clearInterval(id);
  }, []);

  const filtered =
    filter === "all" ? items : items.filter((i) => i.status === filter);

  return (
    <div className="space-y-3">
      <div className="flex gap-2">
        {(["pending", "done", "all"] as StatusFilter[]).map((f) => (
          <Button
            key={f}
            size="xs"
            variant={filter === f ? "default" : "ghost"}
            onClick={() => setFilter(f)}
          >
            {f}
          </Button>
        ))}
      </div>

      {loading ? (
        <p className="text-muted-foreground text-sm">Loading…</p>
      ) : filtered.length === 0 ? (
        <p className="text-muted-foreground text-sm">No items.</p>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Description</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Added</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filtered.map((item) => (
              <TableRow key={item.filename}>
                <TableCell className="max-w-sm truncate">
                  {item.description}
                </TableCell>
                <TableCell>
                  <Badge variant="outline">{item.type}</Badge>
                </TableCell>
                <TableCell>
                  <Badge
                    variant={item.status === "done" ? "secondary" : "default"}
                  >
                    {item.status}
                  </Badge>
                </TableCell>
                <TableCell className="text-muted-foreground">
                  {formatDate(item.added_at)}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}
