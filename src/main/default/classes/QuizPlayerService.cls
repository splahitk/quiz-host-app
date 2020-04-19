public class QuizPlayerService extends QuizAbstractDataService {
    public Quiz_Player__c getFromId(Id playerId) {
        return (Quiz_Player__c) getSingleRecord(
            'Quiz_Player__c',
            [
                SELECT Id, Name, Score__c, Ranking__c
                FROM Quiz_Player__c
                WHERE Id = :playerId
            ]
        );
    }

    public Quiz_Player__c getFromName(String name) {
        return (Quiz_Player__c) getSingleRecord(
            'Quiz_Player__c',
            [SELECT Id FROM Quiz_Player__c WHERE Name = :name]
        );
    }

    public Quiz_Player__c create(String name) {
        Quiz_Player__c player = new Quiz_Player__c(Name = name);
        insert player;
        return player;
    }

    public List<Quiz_Player__c> getPlayersSortedByScore(Integer maxFetchCount) {
        String query = 'SELECT Id, Name, Score__c, Ranking__c FROM Quiz_Player__c ORDER BY Score__c DESC';
        if (maxFetchCount != null) {
            query += ' LIMIT ' + maxFetchCount;
        }
        return Database.query(query);
    }

    public void updateUserScores() {
        List<User> users = new List<User>();
        List<Quiz_Player__c> players = [SELECT Id, Name, Score__c, User__c, Total_Quiz_Points__c FROM Quiz_Player__c WHERE User__c != ''];
        if(players != null && players.size() > 0) { 
            for(Quiz_Player__c p : players) {
                User u = new User(); 
                u.Id = p.User__c; //User to update
                u.Total_Quiz_Points__c = p.Total_Quiz_Points__c + p.Score__c; //Total Quiz Points of User + Score from this Quiz
                users.add(u);
            }
            update users;
        }
    }

    public Map<Id, Quiz_Player__c> getPlayers() {
        return new Map<Id, Quiz_Player__c>(
            [SELECT Id, Score__c FROM Quiz_Player__c]
        );
    }

    public void deleteAnswersAndPlayers() {
        updateUserScores(); //Update User scores before deleting Players and Answers
        delete [SELECT Id FROM Quiz_Answer__c];
        delete [SELECT Id FROM Quiz_Player__c];
    }

    public void assignRanking() {
        List<Quiz_Player__c> players = getPlayersSortedByScore(null);
        Decimal lastScore = 9223372036854775807L; // Long max value
        Integer rank = 0;
        for (Quiz_Player__c player : players) {
            // if previous score is larger than current score, increment rank
            if (lastScore > player.Score__c) {
                rank++;
            }
            player.Ranking__c = rank;
            lastScore = player.Score__c;
        }
        update players;
    }
}
