import Game from '../models/Game';
import User from '../models/User';
import Banner from '../models/Banner';
import Participation from '../models/Participation';

const seedSurvivors = async () => {
  try {
    const existingGames = await Game.countDocuments();
    const existingUsers = await User.countDocuments();
    const existingBanners = await Banner.countDocuments();
    const existingParticipations = await Participation.countDocuments();

    if (existingGames > 0 && existingUsers > 0 && existingBanners > 0 && existingParticipations > 0) {
      console.log('Database already has data, skipping seeding');
      return;
    }

    // Crear usuarios de prueba si no existen
    if (existingUsers === 0) {
      const sampleUsers = [
        {
          username: "admin",
          email: "admin@survivor.com",
          password: "admin123",
          firstName: "Admin",
          lastName: "User",
          lives: 3
        },
        {
          username: "messi10",
          email: "messi@survivor.com",
          password: "messi123",
          firstName: "Lionel",
          lastName: "Messi",
          lives: 1
        },
        {
          username: "ronaldo7",
          email: "ronaldo@survivor.com",
          password: "ronaldo123",
          firstName: "Cristiano",
          lastName: "Ronaldo",
          lives: 3
        },
        {
          username: "neymar11",
          email: "neymar@survivor.com",
          password: "neymar123",
          firstName: "Neymar",
          lastName: "Jr",
          lives: 3
        },
        {
          username: "maradona",
          email: "maradona@survivor.com",
          password: "diego123",
          firstName: "Diego",
          lastName: "Maradona",
          lives: 3
        }
      ];

      // Crear usuarios uno por uno para que se ejecute el middleware de hashing
      for (const userData of sampleUsers) {
        const user = new User(userData);
        await user.save();
      }
      console.log('✅ Sample users seeded successfully');
    }

    // Crear juegos con sistema de jornadas si no existen
    if (existingGames === 0) {
      const now = new Date();
      
      // Función para crear jornadas con partidos
      const createWeeks = (teams: any[]) => {
        const weeks = [];
        
        // Partidos por jornada
        const weekMatches = [
          // Jornada 1
          [
            [teams[0], teams[1]], // Manchester United vs Liverpool
            [teams[2], teams[3]], // Arsenal vs Chelsea  
            [teams[4], teams[5]]  // Manchester City vs Tottenham
          ],
          // Jornada 2
          [
            [teams[1], teams[2]], // Liverpool vs Arsenal
            [teams[3], teams[4]], // Chelsea vs Manchester City
            [teams[5], teams[0]]  // Tottenham vs Manchester United
          ],
          // Jornada 3
          [
            [teams[2], teams[5]], // Arsenal vs Tottenham
            [teams[0], teams[4]], // Manchester United vs Manchester City
            [teams[1], teams[3]]  // Liverpool vs Chelsea
          ],
          // Jornada 4
          [
            [teams[3], teams[5]], // Chelsea vs Tottenham
            [teams[4], teams[1]], // Manchester City vs Liverpool
            [teams[2], teams[0]]  // Arsenal vs Manchester United
          ]
        ];
        
        for (let weekNum = 1; weekNum <= 4; weekNum++) {
          const weekStartMinutes = (weekNum - 1) * 10; // Cada jornada empieza 10 minutos después
          const weekStartDate = new Date(now.getTime() + weekStartMinutes * 60 * 1000);
          const weekEndDate = new Date(weekStartDate.getTime() + 8 * 60 * 1000); // 8 minutos de duración
          
          // Crear partidos para esta jornada
          const matches = [];
          for (let matchNum = 1; matchNum <= 3; matchNum++) {
            const matchMinutes = weekStartMinutes + (matchNum - 1) * 2; // Cada 2 minutos
            const matchDate = new Date(now.getTime() + matchMinutes * 60 * 1000);
            
            const [homeTeam, visitorTeam] = weekMatches[weekNum - 1][matchNum - 1];
            const matchId = `${weekNum}_${matchNum}`;
            
            matches.push({
              matchId: matchId,
              home: homeTeam,
              visitor: visitorTeam,
              date: matchDate,
              week: weekNum,
              isFinished: false,
              status: 'pending',
              result: null,
              bettingDeadline: matchDate
            });
          }
          
          weeks.push({
            weekNumber: weekNum,
            name: `Jornada ${weekNum}`,
            startDate: weekStartDate,
            endDate: weekEndDate,
            matches: matches,
            isActive: weekNum === 1, // Solo la primera jornada activa
            isCompleted: false
          });
        }
        
        return weeks;
      };

      // Función para aplanar todos los partidos en competition (compatibilidad)
      const flattenMatches = (weeks: any[]) => {
        const allMatches: any[] = [];
        weeks.forEach(week => {
          week.matches.forEach((match: any) => {
            allMatches.push(match);
          });
        });
        return allMatches;
      };

      // Definir equipos para cada liga
      const premierLeagueTeams = [
        { name: "Manchester United", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
        { name: "Liverpool", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
        { name: "Arsenal", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
        { name: "Chelsea", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
        { name: "Manchester City", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
        { name: "Tottenham", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" }
      ];

      const championsLeagueTeams = [
        { name: "Real Madrid", flag: "🇪🇸" },
        { name: "Barcelona", flag: "🇪🇸" },
        { name: "Bayern Munich", flag: "🇩🇪" },
        { name: "PSG", flag: "🇫🇷" },
        { name: "Juventus", flag: "🇮🇹" },
        { name: "AC Milan", flag: "🇮🇹" }
      ];

      const premierWeeks = createWeeks(premierLeagueTeams);
      const championsWeeks = createWeeks(championsLeagueTeams);

      const sampleSurvivors = [
        {
          name: "Liga Premier 2025",
          weeks: premierWeeks,
          competition: flattenMatches(premierWeeks), // Todos los partidos aplanados
          startDate: now,
          endDate: new Date(now.getTime() + 40 * 60 * 1000), // 40 minutos después
          maxLives: 3,
          isActive: true,
          currentWeek: 1,
          totalWeeks: 4,
          maxParticipants: 20,
          participantCount: 0
        },
        {
          name: "Champions League 2025",
          weeks: championsWeeks, // Crear otra liga con equipos diferentes
          competition: flattenMatches(championsWeeks),
          startDate: new Date(now.getTime() + 50 * 60 * 1000), // Empieza 50 minutos después
          endDate: new Date(now.getTime() + 90 * 60 * 1000), // Termina 90 minutos después
          maxLives: 3,
          isActive: true,
          currentWeek: 1,
          totalWeeks: 4,
          maxParticipants: 20,
          participantCount: 0
        }
      ];

      // Crear solo en la colección Game (es la que se usa en la aplicación)
      await Game.insertMany(sampleSurvivors);
      console.log('✅ Sample games with weeks seeded successfully');
    }

    // Crear banners de prueba si no existen
    if (existingBanners === 0) {
      const sampleBanners = [
        {
          title: "¡Nuevas Jornadas Disponibles!",
          description: "Únete a las mejores competiciones con sistema de jornadas. ¡Cada jornada tiene múltiples partidos!",
          isActive: true,
          order: 1
        },
        {
          title: "Sistema de Jornadas",
          description: "Ahora cada liga tiene jornadas con 3 partidos cada una. ¡Más oportunidades de demostrar tu conocimiento!",
          isActive: true,
          order: 2
        },
        {
          title: "Premio por Jornada",
          description: "Los mejores jugadores de cada jornada recibirán bonificaciones especiales.",
          isActive: true,
          order: 3
        }
      ];

      await Banner.insertMany(sampleBanners);
      console.log('✅ Sample banners seeded successfully');
    }

    console.log('🎉 Database seeded successfully with weeks system!');

  } catch (error) {
    console.error('❌ Error seeding database:', error);
  }
};

export default seedSurvivors;
