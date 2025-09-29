public with sharing class LoggingEngine_Levels {
    private static final Integer debug = 0;
    private static final Integer info = 1;
    private static final Integer warn = 2;
    private static final Integer error = 3;

    public static Integer getLevel(String level) {
        if (level == null) {
            return 0;
        }
        level = level.toLowerCase().trim();

        switch on (level) {
            when 'debug'
                {return debug;}
            when 'info'
                {return info;}
            when 'warn'
                {return warn;}
            when 'error'
                {return error;}
            when else
                {return debug;}
        }
    }
}