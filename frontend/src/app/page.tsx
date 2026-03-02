import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function Home() {
  return (
    <div className="flex items-center justify-center min-h-screen bg-background">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-3xl font-bold">SONNA</CardTitle>
          <CardDescription>
            Plataforma de automação de chamadas com IA
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <Button asChild className="w-full">
            <a href="/login">Entrar</a>
          </Button>
          <Button asChild variant="outline" className="w-full">
            <a href="/registro">Criar conta</a>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
