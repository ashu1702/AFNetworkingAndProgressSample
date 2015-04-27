//
//  ViewController.m
//  NactemAsyncTest
//
//  Created by Tiwari, Ashutosh (GE Global Research) on 4/26/15.
//  Copyright (c) 2015 Tiwari, Ashutosh (GE Global Research). All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"

#define STATUS_BAR_HEIGHT   20.0f
#define SEARCH_BAR_HEIGHT   44.0f
#define Prefix_SF       @"sf"
#define Prefix_LF       @"lf"
#define KEY_LFS         @"lfs"

static NSString *cellIdentifier = @"SyncCell";
static NSString * const BaseURLString = @"http://www.nactem.ac.uk/software/acromine/dictionary.py?";

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UISearchBar * searchBar;
@property(nonatomic,strong) NSMutableArray * apiResults;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.searchBar.frame = CGRectMake(0, STATUS_BAR_HEIGHT, self.view.frame.size.width, SEARCH_BAR_HEIGHT);
}

-(void) getAcronymsInitilisationFor:(NSString*)term withPrefix:(NSString*)prefix
{
    //Build the URL String
    NSString *string = [NSString stringWithFormat:@"%@%@=%@", BaseURLString,prefix,term];
    NSString * completeString = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:completeString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Show ProgressView
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        //Add
        operation.responseSerializer.acceptableContentTypes = [operation.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            //Initialize apiResults array so that we have new set of results displayed everytime we have one
            self.apiResults = [NSMutableArray new];
            NSArray * rawResultDict = (NSArray *)responseObject;
            NSDictionary * results = [rawResultDict firstObject];
            if (results) {
                if ([[term componentsSeparatedByString:@" "] count] > 1) {
                    self.apiResults = [NSMutableArray arrayWithArray:@[[results objectForKey:Prefix_SF]]];
                }
                else {
                    NSArray * temp = [results objectForKey:KEY_LFS];
                    for (NSDictionary*dict in temp) {
                        [self.apiResults addObject:[dict objectForKey:Prefix_LF]];
                    }
                }
                self.title = @"Results";
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //Log any failure
            NSLog(@"An Error occurred: %@",[error description]);
        }];
        //Start the operation
        [operation start];
    });
}

#pragma  mark UITableView delegate methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.apiResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * syncCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (syncCell == nil) {
        syncCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    syncCell.textLabel.text = [self.apiResults objectAtIndex:indexPath.row];
    //Remove the Progress view
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    return syncCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //Do something
}

#pragma mark SearchBar delegate methods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //make the API call here
    if (searchText.length >1) { // Only call the API when the number of character increases to 2 atleast
        self.apiResults = nil; // Make sure the array has nothing
        // Check if the input is multiple words so that we know its longform
        if ([searchText componentsSeparatedByString:@" "].count > 1) {
            [self getAcronymsInitilisationFor:searchText withPrefix:@"lf"];
        }
        else { // We know its a short form
            [self getAcronymsInitilisationFor:searchText withPrefix:@"sf"];
        }
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.apiResults = nil;
    [self.searchDisplayController.searchResultsTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
