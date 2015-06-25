public class SaaSlastCaseComment {
    public Id caseId {get; set;}
    public String NewLine {
        get { return '\r\n'; }
        set;
    }
    
    public String lastCaseComment { 
        get {
            String lcc = '';
            for( CaseComment caseCom : [SELECT CommentBody FROM CaseComment WHERE ParentId = :caseId ORDER BY LastModifiedDate DESC LIMIT 1]) {
              lcc = caseCom.CommentBody;
            }
            return lcc;
        }
        set;
    }
    
    public String solutionSubjectAndDescription {
        get {
            String lcc = '';
            for( CaseSolution caseSol : [Select c.Solution.SolutionNote, c.Solution.SolutionName, c.SolutionId, c.CaseId From CaseSolution c WHERE c.CaseId=:caseId LIMIT 1]) {          
                  lcc = caseSol.Solution.SolutionName + ' ' + caseSol.Solution.SolutionNote ;
            }
            return lcc;
        }
        set;
    }
}