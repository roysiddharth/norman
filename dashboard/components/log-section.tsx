"use client";

import { useEffect, useState } from "react";
import ReactMarkdown from "react-markdown";
import { ScrollArea } from "@/components/ui/scroll-area";

type LogData = {
  date: string;
  content: string | null;
};

export function LogSection() {
  const [log, setLog] = useState<LogData | null>(null);
  const [loading, setLoading] = useState(true);

  function fetchLog() {
    fetch("/api/log")
      .then((r) => r.json())
      .then((data: LogData) => {
        setLog(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }

  useEffect(() => {
    fetchLog();
    const id = setInterval(fetchLog, 15_000);
    return () => clearInterval(id);
  }, []);

  if (loading) {
    return <p className="text-muted-foreground text-sm">Loading…</p>;
  }

  if (!log?.content) {
    return <p className="text-muted-foreground text-sm">No runs logged today.</p>;
  }

  return (
    <ScrollArea className="h-96">
      <div className="prose prose-sm dark:prose-invert max-w-none pr-4">
        <ReactMarkdown>{log.content}</ReactMarkdown>
      </div>
    </ScrollArea>
  );
}
