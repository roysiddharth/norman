import { ThemeToggle } from "@/components/theme-toggle";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { QueueSection } from "@/components/queue-section";
import { RoutinesSection } from "@/components/routines-section";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="flex items-center justify-between px-6 py-4 border-b">
        <h1 className="text-xl font-semibold">Norman</h1>
        <ThemeToggle />
      </header>

      <main className="flex-1 p-6 space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Queue</CardTitle>
          </CardHeader>
          <CardContent>
            <QueueSection />
          </CardContent>
        </Card>

        <Separator />

        <Card>
          <CardHeader>
            <CardTitle>Routines</CardTitle>
          </CardHeader>
          <CardContent>
            <RoutinesSection />
          </CardContent>
        </Card>

        <Separator />

        <Card>
          <CardHeader>
            <CardTitle>Log</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-sm">Loading…</p>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
