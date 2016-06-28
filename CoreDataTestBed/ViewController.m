

#import "ViewController.h"
#import <sys/sysctl.h>
#import "sys/utsname.h"
#import <CoreData/CoreData.h>
#import "TestEntity.h"

typedef NS_ENUM(NSUInteger, switchMOCType) {
    SelectedParentMOC,
    SelectedSonMOC,
};

typedef NS_ENUM(NSUInteger, switchDataType) {
    printPDataSegment=0,
    printSDataSegment,
    printCountSegment,
};

typedef NS_ENUM(NSUInteger, switchGetObjectType) {
    findObjectIdWithExist=0,
    findObjectId,
    findObjectIdWithRegister,
};

typedef NS_ENUM(NSUInteger, switchPrintMethodType) {
    printDataFromObjectId,
    printDataFromObjectPass,
    printDataFromFetchedRequest,
};
@interface ViewController()<NSFetchedResultsControllerDelegate>{
    NSManagedObjectID *entityTempObjectId, *entityPersistentObjectId;
    NSManagedObjectContext *currentMOC;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchPrintMethodButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchMOCButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchFindObjectMethodButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchTempIDButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchFRCDataButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchPrintDataButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextView *fetcherTextView;
@property (nonatomic,strong) NSManagedObjectContext *moc,*subContext;
@property (nonatomic,strong) NSFetchedResultsController *pFetcher,*sFetcher;
@property (nonatomic,strong) TestEntity *myObject, *myFetchedObject;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMOC];
    self.textView.text=@" MO's MOC: \n isFault: \t\t\t isDeleted: \n faultingState: \t\t isInserted: \n isUpdated: \t\t hasChanges: \n isTemporaryID: \n objectID: \n MO's parentMOC: \n data: \n";
    self.fetcherTextView.text=@"You don't have FRC";
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (IBAction)resetAll:(id)sender {
    [self initMOC];
    self.textView.text=@" MO's MOC: \n isFault: \t\t\t isDeleted: \n faultingState: \t\t isInserted: \n isUpdated: \t\t hasChanges: \n isTemporaryID: \n objectID: \n MO's parentMOC: \n data: \n";
    self.fetcherTextView.text=@"You don't have FRC";
    self.pFetcher=nil;
    self.sFetcher=nil;
    entityTempObjectId=nil;
    entityPersistentObjectId=nil;
    self.myFetchedObject=nil;
}
- (IBAction)initFetcher:(id)sender {
    NSFetchRequest *request=[NSFetchRequest
                             fetchRequestWithEntityName:@"TestEntity"];
    NSSortDescriptor *sorter=[NSSortDescriptor
                              sortDescriptorWithKey:@"name" ascending:YES];
    [request setSortDescriptors:@[sorter]];
    switch (self.switchMOCButton.selectedSegmentIndex) {
        case SelectedParentMOC:
            self.pFetcher=[[NSFetchedResultsController alloc]
                           initWithFetchRequest:request
                           managedObjectContext:self.moc
                           sectionNameKeyPath:@"money"
                           cacheName:nil];
            self.pFetcher.delegate=self;
            [self.pFetcher performFetch:nil];
            break;
        case SelectedSonMOC:
            self.sFetcher=[[NSFetchedResultsController alloc]
                           initWithFetchRequest:request
                           managedObjectContext:self.subContext
                           sectionNameKeyPath:nil
                           cacheName:nil];
            self.sFetcher.delegate=self;
            [self.sFetcher performFetch:nil];
        default:
            break;
    }
}

- (IBAction)addData:(id)sender {
    TestEntity *testEntity;
    testEntity = [NSEntityDescription insertNewObjectForEntityForName:@"TestEntity" inManagedObjectContext:currentMOC];
    testEntity.name=([currentMOC isEqual:self.subContext])?@"child":@"parent";
    testEntity.money=([currentMOC isEqual:self.subContext])?@2:@1;
    entityTempObjectId=testEntity.objectID;
    self.myObject=testEntity;
}
- (IBAction)saveData:(id)sender {
    [currentMOC save:nil];
    entityPersistentObjectId=self.myObject.objectID;
}

- (IBAction)deleteData:(id)sender {
    TestEntity *testEntity;
    switch (self.switchPrintMethodButton.selectedSegmentIndex) {
        case printDataFromObjectId:
            testEntity=(TestEntity *)[self getObjectIdWithChooseMethod:currentMOC];
            if (!testEntity) {
                self.textView.text=@"You can't delete The MO when it is nil";
                return;
            }
            [currentMOC deleteObject:testEntity];
            break;
        case printDataFromObjectPass:{
            if (!self.myObject) {
                self.textView.text=@"You can't delete The MO when it is nil";
                return;
            }
            [currentMOC deleteObject:self.myObject];
        }
        case printDataFromFetchedRequest:{
            if (!self.myFetchedObject) {
                self.textView.text=@"You can't delete The MO when it is nil";
                return;
            }
            [currentMOC deleteObject:self.myFetchedObject];
        }
        default:
            break;
    }
    
    
}
- (IBAction)modifyData:(id)sender {
    NSManagedObjectID *objectId;
    if (self.switchTempIDButton.selectedSegmentIndex == 0) {
        objectId = entityTempObjectId;
    }else{
        objectId = entityPersistentObjectId;
    }
    TestEntity *entity=(TestEntity *)[currentMOC objectWithID:objectId];
    entity.name = ([currentMOC isEqual:self.subContext])?@"M-child":@"M-parent";
    entity.money = ([currentMOC isEqual:self.subContext])?@22:@11;
}

-(IBAction)printLog:(id)sender{
    switch (self.switchPrintMethodButton.selectedSegmentIndex) {
        case printDataFromObjectId:
            [self printObjectAttributesFromId];
            break;
        case printDataFromObjectPass:
            [self printObjectAttributesFromPass];
            break;
        case printDataFromFetchedRequest:
            [self printFromRequest];
            break;
        default:
            break;
    }
}

- (IBAction)clickSwithDataTypeButton:(id)sender {
    [self printFetcherContent];
}
- (IBAction)switchMOCClicked:(id)sender {
    if (self.switchMOCButton.selectedSegmentIndex==SelectedSonMOC) {
        currentMOC=self.subContext;
    }else{
        currentMOC=self.moc;
    }
}

#pragma mark - private method

-(void)printFetcherContent{
    [self.pFetcher performFetch:nil];
    [self.sFetcher performFetch:nil];
    NSString *result;
    switch (self.switchFRCDataButton.selectedSegmentIndex) {
        case printPDataSegment:
            result=(self.pFetcher)?[NSString stringWithFormat:@"parentContext: \n %@",[self.pFetcher fetchedObjects]]:@"You don't have FRC";
            break;
        case printSDataSegment:
            result=(self.sFetcher)?[NSString stringWithFormat:@"parentContext: \n %@",[self.sFetcher fetchedObjects]]:@"You don't have FRC";
            break;
        case printCountSegment:
            result=[NSString stringWithFormat:@"parentContext: \n %lu\n sonContext:\n %lu\n",[self.pFetcher fetchedObjects].count,[self.sFetcher fetchedObjects].count];
            break;
        default:
            break;
    }
    self.fetcherTextView.text=result;
}

- (void)printFromRequest{
    if (!self.myFetchedObject) {
        NSFetchRequest *request=[[NSFetchRequest alloc]initWithEntityName:@"TestEntity"];
        NSPredicate *predicate=[NSPredicate predicateWithFormat:@"name = 1"];
        request.predicate=predicate;
        NSArray *dataArray=[currentMOC executeFetchRequest:request error:nil];
        self.myFetchedObject = [dataArray firstObject];
    }
    self.textView.text=[self getOutputString:self.myFetchedObject];
}

-(void)printObjectAttributesFromId{
    TestEntity *testEntity;
    testEntity=(TestEntity *)[self getObjectIdWithChooseMethod:currentMOC];
    self.textView.text=[self getOutputString:testEntity];
}

-(void)printObjectAttributesFromPass{
    self.textView.text=[self getOutputString:self.myObject];
}

-(NSString *) getOutputString:(TestEntity *)anObject{
    NSString *result = [NSString stringWithFormat:@" MO's MOC:%@ \n isFault:%d \t\t\t isDeleted:%d \n faultingState:%lu \t\t isInserted:%d \n isUpdated:%d \t\t hasChanges:%d \n isTemporaryID:%d \n objectID:%@ \n MO's parentMOC:%@ \n",anObject.managedObjectContext,anObject.isFault,anObject.isDeleted,anObject.faultingState,anObject.isInserted,anObject.isUpdated,anObject.hasChanges,anObject.objectID.isTemporaryID,anObject.objectID,anObject.managedObjectContext.parentContext];
    if (self.switchPrintDataButton.selectedSegmentIndex==0) {
        result=[result stringByAppendingFormat:@" data:%@,%@\n",anObject.name,anObject.money];
    }
    return result;
}

-(void)initMOC{
    self.moc = [self getManagedObjectContext];
    self.subContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [self.subContext setParentContext:self.moc];
    currentMOC=self.moc;
}

-(NSManagedObject *) getObjectIdWithChooseMethod:(NSManagedObjectContext *)moc{
    NSManagedObjectID *objectId=(self.switchTempIDButton.selectedSegmentIndex==0)?entityTempObjectId:entityPersistentObjectId;
    if (!objectId) {
        self.textView.text=@"objectId is nil, add data first";
        return nil;
    }
    switch (self.switchFindObjectMethodButton.selectedSegmentIndex) {
        case findObjectId:
            return [moc objectWithID:objectId];
            break;
        case findObjectIdWithExist:
            return [moc existingObjectWithID:objectId error:nil];
            break;
        case findObjectIdWithRegister:
            return [moc objectRegisteredForID:objectId];
            break;
    }
    return nil;
}

#pragma mark- ----persistent Stack----
#pragma mark- Persistent Stack- MOC

-(NSManagedObjectContext *)getManagedObjectContext{
    NSManagedObjectContext *moc=[[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSMainQueueConcurrencyType];
    moc.undoManager=[[NSUndoManager alloc]init];
    [moc setPersistentStoreCoordinator:[self getCoordinator]];
    return moc;
}

#pragma mark- Persistent Stack- Coordinator

-(NSPersistentStoreCoordinator *)getCoordinator{
    NSPersistentStoreCoordinator *coordinator =
    [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:[self getModel]];
    
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption:@YES,
                               NSInferMappingModelAutomaticallyOption:@YES
                               };
    
    [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:[self getFilePath]
                                    options:options
                                      error:nil];
    return coordinator;
}

#pragma mark- Persistent Stack- Model

-(NSManagedObjectModel *)getModel{
    NSURL *url=[[NSBundle mainBundle]URLForResource:@"CoreDataTestBed"
                                      withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc]
                                   initWithContentsOfURL:url];
    return model;
}

#pragma mark- Persistent Stack- File Path

-(NSURL *)getFilePath{
    NSURL *storeUrl=[[[NSFileManager defaultManager]
                      URLsForDirectory:NSDocumentationDirectory
                      inDomains:NSUserDomainMask]lastObject];
    storeUrl = [storeUrl URLByAppendingPathComponent:@"test.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeUrl.path]) {
        NSLog(@"%d",[[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil]);
    }else{
        [[NSFileManager defaultManager] createDirectoryAtURL:storeUrl
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
    }
    return storeUrl;
}

#pragma mark- FetchResultController Delegation

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type{
    NSLog(@"sectionInfo:%@",[sectionInfo name]);
    NSLog(@"type:%ld",type);
}

-(void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath{
    [self printFetcherContent];

    /*
     1. You can got the fetchResultsController, object, old indextPath,
     changeType and new indexPath to update your UI or other things
     when the MOC got changes.
     2. old/new indexPath mean that object index in FetchedResultsController
     */
    switch (type) {
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeDelete:
            break;
        case NSFetchedResultsChangeInsert:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        default:
            break;
    }
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
}

@end




