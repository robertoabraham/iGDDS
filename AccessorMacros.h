#ifndef ACCESSOR_MACROS
#define ACCESSOR_MACROS

//---	This file expands the accessor macros

#define newBool(x)	(x ? [[NSNumber numberWithBool:x] retain] : nil)
#define newInt(x)	[[NSNumber numberWithInt:x]  retain]
#define newChar(x)	[[NSNumber numberWithChar:x] retain]
#define makeBool(x)	(x ? [NSNumber numberWithBool:x] : nil)
#define makeInt(x)	[NSNumber numberWithInt:x]
#define makeChar(x)	[NSNumber numberWithChar:x]
#define toInt(x)	[x intValue]
#define toBool(x)	[x boolValue]
#define toString(x)	[x stringValue]

#define	setAccessor( var,setVar ) \
-(void)setVar:newVar { \
	if ( newVar!=var) {  \
        if ( newVar!=(id)self ) \
            [newVar retain]; \
		if ( var && var!=(id)self) \
			[var release]; \
		var = newVar; \
	} \
} \

#define readAccessor( var )\
-var						{	return var;			}

#define relayReadAccessor( var, delegate ) \
-var\
{\
    if ( var ) {\
        return var;\
    } else {\
        return [delegate var];\
    }\
}\

#define idAccessor( var, setVar ) \
readAccessor( var )\
setAccessor(var,setVar )

#define relayAccessor( var, setVar, delegate )\
relayReadAccessor( var , delegate )\
setAccessor( var, setVar )

#define	idAccessor_h( var,setVar ) -(void)setVar:newVar; \
-var;

#define scalarAccessor( scalarType, var, setVar ) \
-(void)setVar:(scalarType)newVar	{	var=newVar;	} \
-(scalarType)var					{	return var;	} 
#define scalarAccessor_h( scalarType, var, setVar ) \
-(void)setVar:(scalarType)newVar; \
-(scalarType)var;

#define intAccessor( var, setVar )	scalarAccessor( int, var, setVar )
#define intAccessor_h( var, setVar )	scalarAccessor_h( int, var, setVar )
#define floatAccessor(var,setVar )  scalarAccessor( float, var, setVar )
#define floatAccessor_h(var,setVar )  scalarAccessor_h( float, var, setVar )
#define boolAccessor(var,setVar )  scalarAccessor( BOOL, var, setVar )
#define boolAccessor_h(var,setVar )  scalarAccessor_h( BOOL, var, setVar )

#endif /* ACCESSOR_MACROS */